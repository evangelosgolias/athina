#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional


# ============================================================
# Data models
# ============================================================

@dataclass
class ParamDoc:
    name: str
    type_name: str
    description: str
    optional: bool = False


@dataclass
class SignatureParam:
    name: str
    type_name: str
    optional: bool = False


@dataclass
class FunctionDoc:
    name: str
    signature: str
    return_type: str = "Variable"
    brief: str = ""
    details: str = ""
    params: List[ParamDoc] = field(default_factory=list)
    returns: str = ""
    notes: List[str] = field(default_factory=list)
    example: List[str] = field(default_factory=list)


@dataclass
class ModuleDoc:
    name: str = ""
    brief: str = ""
    details: str = ""


# ============================================================
# Helpers
# ============================================================

FUNCTION_HEADER_RE = re.compile(
    r"""
    ^\s*
    (?:(?:static|threadsafe)\s+)*       # optional modifiers before Function
    Function(?:/(?P<return_flag>[A-Za-z]+))?  # optional return modifier
    \s+
    (?:\[(?P<named_returns>[^\]]+)\]\s+)?  # optional named return list
    (?P<function_name>[A-Za-z_]\w*)     # function name
    \s*\(
    """,
    re.IGNORECASE | re.VERBOSE,
)


def return_type_from_flag(flag: Optional[str]) -> str:
    if not flag:
        return "Variable"
    flag = flag.upper()
    if flag == "S":
        return "String"
    if flag == "WAVE":
        return "Wave"
    if flag == "DF":
        return "DFREF"
    if flag == "C":
        return "Complex"
    return "Variable"


def strip_doc_prefix(line: str) -> str:
    return re.sub(r"^\s*///\s?", "", line.rstrip("\n"))


def safe_output_name(ipf_path: Path, input_dir: Path) -> str:
    rel = ipf_path.relative_to(input_dir)
    return "__".join(rel.with_suffix("").parts)


def display_type(type_text: str) -> str:
    """Normalize common Igor parameter types for display."""
    text = re.sub(r"\s+", " ", type_text.strip())
    if not text:
        return "Variable"

    aliases = {
        "variable": "Variable",
        "int": "Integer",
        "string": "String",
        "wave": "Wave",
        "dfref": "DFREF",
    }
    lower = text.lower()
    if lower in aliases:
        return aliases[lower]
    if lower.startswith("wave/"):
        return "Wave" + text[4:]
    if lower.startswith("struct "):
        return "STRUCT " + text[7:]
    if lower.startswith("funcref "):
        return "FUNCREF " + text[8:]
    return text


def parse_signature_params(signature: str) -> List[SignatureParam]:
    """Parse Igor parameters, preserving order, types, and optional brackets."""
    parts = []
    current = []
    nested_depth = 0
    optional_depth = 0

    for ch in signature:
        if ch in "({":
            nested_depth += 1
        elif ch in ")}":
            nested_depth -= 1

        if ch == "[":
            optional_depth += 1

        if ch == "," and nested_depth == 0:
            parts.append(("".join(current).strip(), optional_depth > 0))
            current = []
        else:
            current.append(ch)

        if ch == "]":
            optional_depth -= 1

    tail = "".join(current).strip()
    if tail:
        parts.append((tail, optional_depth > 0 or "[" in tail))

    result: List[SignatureParam] = []
    optional_section = False
    for raw, inside_optional in parts:
        if "[" in raw:
            optional_section = True

        text = raw.replace("[", " ").replace("]", " ").strip()
        if "=" in text:
            text = text.split("=", 1)[0].strip()

        name_match = re.search(r"&?([A-Za-z_]\w*)\s*$", text)
        if not name_match:
            continue

        name = name_match.group(1)
        type_text = text[:name_match.start()].strip().rstrip("&").strip()
        result.append(
            SignatureParam(
                name=name,
                type_name=display_type(type_text),
                optional=inside_optional or optional_section,
            )
        )

    return result


# ============================================================
# Module doc parsing
# ============================================================

def find_module_doc(lines: List[str], fallback_name: str) -> ModuleDoc:
    """
    Find the first /// block containing @module anywhere near the top of the file,
    even if the file begins with #pragma, blank lines, or regular comments.
    """
    module = ModuleDoc(name=fallback_name)

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.lstrip().startswith("///"):
            block = []
            while i < len(lines) and lines[i].lstrip().startswith("///"):
                block.append(lines[i])
                i += 1

            joined = "\n".join(block)
            if "@module" in joined:
                return parse_module_doc(block, fallback_name)
            continue

        i += 1

    return module


def parse_module_doc(block_lines: List[str], fallback_name: str) -> ModuleDoc:
    module = ModuleDoc(name=fallback_name)
    current = None

    for raw in block_lines:
        line = strip_doc_prefix(raw).strip()

        if not line:
            continue

        if line.startswith("@module"):
            module.name = line[len("@module"):].strip() or fallback_name
            current = None
        elif line.startswith("@brief"):
            module.brief = line[len("@brief"):].strip()
            current = None
        elif line.startswith("@details"):
            module.details = line[len("@details"):].strip()
            current = "details"
        else:
            if current == "details":
                module.details += ("\n" if module.details else "") + line

    return module


# ============================================================
# Function doc parsing
# ============================================================

def strip_legacy_param_type(description: str, signature_type: str) -> str:
    """Remove an old explicit type token when the signature already supplies it."""
    description = re.sub(r"^\(optional\)[.;]?\s*", "", description, flags=re.IGNORECASE)
    description = re.sub(r"^Optional[.;]?\s*", "", description, flags=re.IGNORECASE)
    if not description:
        return ""

    first, *remainder = description.split(maxsplit=1)
    known_types = {"variable", "int", "integer", "string", "wave", "dfref", "complex"}
    signature_base = signature_type.split("/", 1)[0].lower()
    if first.rstrip(":").lower() in known_types and (
        first.rstrip(":").lower() == signature_base
        or {first.rstrip(":").lower(), signature_base} <= {"int", "integer", "variable"}
    ):
        return remainder[0] if remainder else ""
    return description


def parse_docblock(doc_lines: List[str], func_name: str, signature: str, return_type: str) -> FunctionDoc:
    doc = FunctionDoc(name=func_name, signature=signature, return_type=return_type)
    signature_params = parse_signature_params(signature)
    param_descriptions = {}
    current = None
    current_param = None

    for raw in doc_lines:
        line = strip_doc_prefix(raw)
        stripped = line.strip()

        if not stripped:
            if current == "example":
                doc.example.append("")
            continue

        if stripped.startswith("@function"):
            current = None

        elif stripped.startswith("@brief"):
            doc.brief = stripped[len("@brief"):].strip()
            current = "brief"

        elif stripped.startswith("@details"):
            doc.details = stripped[len("@details"):].strip()
            current = "details"

        elif stripped.startswith("@param"):
            rest = stripped[len("@param"):].strip()
            parts = rest.split(maxsplit=1)
            if not parts:
                continue
            name = parts[0].strip("[]").lstrip("&")
            param_descriptions[name] = parts[1] if len(parts) == 2 else ""
            current = "param"
            current_param = name

        elif stripped.startswith("@returns"):
            rest = stripped[len("@returns"):].strip()
            ret_parts = rest.split(maxsplit=1)
            if len(ret_parts) == 2 and ret_parts[0] in {"Variable", "String", "Wave", "DFREF", "Complex"}:
                doc.return_type = ret_parts[0]
                doc.returns = ret_parts[1]
            else:
                doc.returns = rest
            current = "returns"

        elif stripped.startswith("@note"):
            doc.notes.append(stripped[len("@note"):].strip())
            current = "note"

        elif stripped.startswith("@example"):
            current = "example"

        else:
            if current == "brief":
                doc.brief += (" " if doc.brief else "") + stripped
            elif current == "details":
                doc.details += ("\n" if doc.details else "") + stripped
            elif current == "param" and current_param:
                param_descriptions[current_param] += (
                    "\n" if param_descriptions[current_param] else ""
                ) + stripped
            elif current == "returns":
                doc.returns += (" " if doc.returns else "") + stripped
            elif current == "note" and doc.notes:
                doc.notes[-1] += " " + stripped
            elif current == "example":
                doc.example.append(line)

    for parameter in signature_params:
        description = strip_legacy_param_type(
            param_descriptions.get(parameter.name, ""), parameter.type_name
        )
        doc.params.append(
            ParamDoc(
                name=parameter.name,
                type_name=parameter.type_name,
                description=description,
                optional=parameter.optional,
            )
        )

    return doc


def collect_documented_functions(lines: List[str]) -> List[FunctionDoc]:
    results: List[FunctionDoc] = []

    i = 0
    pending_doc: List[str] = []

    while i < len(lines):
        line = lines[i]

        # collect a doc block
        if line.lstrip().startswith("///"):
            block = []
            while i < len(lines) and lines[i].lstrip().startswith("///"):
                block.append(lines[i])
                i += 1

            # Only explicit function blocks belong to a function. This prevents
            # module-level and free-form /// comments from being attached to the
            # next procedure by accident.
            joined = "\n".join(block)
            pending_doc = block if "@function" in joined else []

            # allow blank lines between docs and function
            while i < len(lines) and not lines[i].strip():
                i += 1
            continue

        # detect function header
        match = FUNCTION_HEADER_RE.match(line)
        if match:
            retflag = match.group("return_flag")
            func_name = match.group("function_name")
            return_type = (
                "Multiple values"
                if match.group("named_returns")
                else return_type_from_flag(retflag)
            )

            header_lines = [line.rstrip("\n")]
            paren_balance = line.count("(") - line.count(")")
            i += 1

            while i < len(lines) and paren_balance > 0:
                header_lines.append(lines[i].rstrip("\n"))
                paren_balance += lines[i].count("(") - lines[i].count(")")
                i += 1

            header_text = " ".join(h.strip() for h in header_lines)

            sig_match = re.search(r"\((.*)\)", header_text)
            signature = sig_match.group(1).strip() if sig_match else ""

            if pending_doc:
                results.append(parse_docblock(pending_doc, func_name, signature, return_type))

            pending_doc = []
            continue

        # any non-doc non-function line clears pending docs
        if line.strip():
            pending_doc = []

        i += 1

    return results


# ============================================================
# Markdown rendering
# ============================================================

def render_function_markdown(fn: FunctionDoc) -> List[str]:
    lines: List[str] = []

    lines.append(f"## `{fn.name}`")
    lines.append("")

    lines.append("**Signature**")
    lines.append("")
    lines.append("```igorpro")
    lines.append(f"{fn.name}({fn.signature})")
    lines.append("```")
    lines.append("")

    if fn.brief:
        lines.append(fn.brief)
        lines.append("")

    if fn.details:
        lines.append(fn.details)
        lines.append("")

    if fn.params:
        lines.append("### Parameters")
        lines.append("")
        for p in fn.params:
            attributes = [p.type_name] if p.type_name else []
            if p.optional:
                attributes.append("optional")
            attribute_part = f" *({', '.join(attributes)})*" if attributes else ""
            description = p.description.replace("\n", "<br>")
            desc_part = f": {description}" if description else ""
            lines.append(f"- `{p.name}`{attribute_part}{desc_part}")
        lines.append("")

    lines.append("### Returns")
    lines.append("")
    if fn.returns:
        lines.append(f"- **{fn.return_type}**: {fn.returns}")
    else:
        lines.append(f"- **{fn.return_type}**")
    lines.append("")

    for note in fn.notes:
        lines.append("```{note}")
        lines.append(note)
        lines.append("```")
        lines.append("")

    if fn.example:
        lines.append("### Example")
        lines.append("")
        lines.append("```{code-block} igorpro")
        for ex_line in fn.example:
            lines.append(ex_line.rstrip())
        lines.append("```")
        lines.append("")

    return lines


def render_module_markdown(module_doc: ModuleDoc, functions: List[FunctionDoc], rel_source: str) -> str:
    lines: List[str] = []

    lines.append(f"# {module_doc.name}")
    lines.append("")
    lines.append(f"**Source file:** `{rel_source}`")
    lines.append("")

    if module_doc.brief:
        lines.append(module_doc.brief)
        lines.append("")

    if module_doc.details:
        lines.append(module_doc.details)
        lines.append("")

    lines.append("```{contents}")
    lines.append(":local:")
    lines.append(":depth: 2")
    lines.append("```")
    lines.append("")

    if functions:
        for fn in functions:
            lines.extend(render_function_markdown(fn))
            lines.append("")
    else:
        lines.append("```{note}")
        lines.append("No documented functions were detected in this file.")
        lines.append("```")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def render_index_markdown(module_paths: List[str], title: str = "API Documentation") -> str:
    lines = [
        f"# {title}",
        "",
        "```{toctree}",
        ":maxdepth: 2",
        "",
    ]
    lines.extend(module_paths)
    lines.extend(["```", ""])
    return "\n".join(lines)


# ============================================================
# File processing
# ============================================================

def process_file(ipf_path: Path, input_dir: Path, output_dir: Path) -> tuple[str, int]:
    text = ipf_path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()

    module_doc = find_module_doc(lines, ipf_path.stem)
    functions = collect_documented_functions(lines)

    out_name = safe_output_name(ipf_path, input_dir)
    rel_source = str(ipf_path.relative_to(input_dir))

    out_path = output_dir / f"{out_name}.md"
    out_path.write_text(
        render_module_markdown(module_doc, functions, rel_source),
        encoding="utf-8",
    )
    return out_name, len(functions)


def build_docs(input_dir: Path, docs_dir: Path) -> None:
    api_dir = docs_dir / "docs/api"
    api_dir.mkdir(parents=True, exist_ok=True)

    # This directory is generated output. Remove stale module pages left by
    # renamed or deleted source files before rebuilding the index.
    for old_page in api_dir.glob("*.md"):
        old_page.unlink()

    ipf_files = sorted(input_dir.rglob("ATH_*.ipf")) # Here filter files for parsing
    if not ipf_files:
        print(f"No .ipf files found under {input_dir}")
        return

    module_paths: List[str] = []
    function_count = 0

    for ipf_path in ipf_files:
        name, documented_functions = process_file(ipf_path, input_dir, api_dir)
        module_paths.append(f"api/{name}")
        function_count += documented_functions

    index_md = docs_dir / "docs/index.md"
    index_md.write_text(render_index_markdown(module_paths), encoding="utf-8")

    print(f"Found {len(ipf_files)} .ipf files")
    print(f"Generated {len(module_paths)} documentation pages")
    print(f"Documented {function_count} functions")


# ============================================================
# CLI
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate MyST Markdown API docs from documented Igor Pro .ipf files.")
    parser.add_argument("input_dir", nargs="?", default="/Users/evagol/Library/CloudStorage/OneDrive-LundUniversity/Programming/athina/src/athina", help="Parent directory to scan recursively for .ipf files")
    parser.add_argument("docs_dir", nargs="?", default="/Users/evagol/Library/CloudStorage/OneDrive-LundUniversity/Programming/athina/apidoc", help="API documentation project directory containing the docs/ Sphinx source directory")
    args = parser.parse_args()

    input_dir = Path(args.input_dir).resolve()
    docs_dir = Path(args.docs_dir).resolve()

    if not input_dir.exists():
        raise SystemExit(f"Input directory does not exist: {input_dir}")

    build_docs(input_dir, docs_dir)
    print(f"Done. Generated MyST Markdown docs in: {docs_dir}")


if __name__ == "__main__":
    main()
