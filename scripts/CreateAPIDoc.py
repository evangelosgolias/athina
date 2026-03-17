#!/Users/evagol/miniconda3/bin/python3
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional


# -----------------------------
# Data models
# -----------------------------

@dataclass
class ParamDoc:
    name: str
    type_name: str
    description: str


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


# -----------------------------
# Regexes
# -----------------------------

# Module doc block must be the first /// block in the file.
MODULE_BLOCK_RE = re.compile(r"\A((?:[ \t]*///.*\n)+)", re.MULTILINE)

# Supports:
#   Function Name(...)
#   Function/S Name(...)
#   Function/WAVE Name(...)
#   Function/DF Name(...)
# Optional "static".
FUNC_RE = re.compile(
    r"""
    ^
    (?P<indent>[ \t]*)
    (?P<static>static[ \t]+)?
    Function(?:/(?P<retflag>S|WAVE|DF))?
    [ \t]+
    (?P<name>[A-Za-z_]\w*)
    [ \t]*
    \((?P<sig>.*?)\)
    """,
    re.MULTILINE | re.VERBOSE,
)

# Doc block immediately preceding a function.
DOC_PLUS_FUNC_RE = re.compile(
    r"""
    (?P<doc>(?:^[ \t]*///.*\n)+)
    (?P<func>
        ^[ \t]*
        (?:static[ \t]+)?
        Function(?:/(?:S|WAVE|DF))?
        [ \t]+
        [A-Za-z_]\w*
        [ \t]*\(
        .*?
        \)
    )
    """,
    re.MULTILINE | re.VERBOSE,
)


# -----------------------------
# Helpers
# -----------------------------

def return_type_from_flag(flag: Optional[str]) -> str:
    if flag == "S":
        return "String"
    if flag == "WAVE":
        return "Wave"
    if flag == "DF":
        return "DFREF"
    return "Variable"


def strip_doc_prefix(line: str) -> str:
    return re.sub(r"^[ \t]*///[ \t]?", "", line.rstrip("\n"))


def markdown_escape(text: str) -> str:
    # Minimal escaping for Markdown headings / formatting collisions.
    return text.replace("\\", "\\\\")


def extract_module_block(text: str) -> Optional[str]:
    match = MODULE_BLOCK_RE.match(text)
    if not match:
        return None
    block = match.group(1)
    # Only treat it as module docs if it actually contains @module.
    if "@module" not in block:
        return None
    return block


def parse_module_doc(docblock: str, fallback_name: str) -> ModuleDoc:
    module = ModuleDoc(name=fallback_name)
    current: Optional[str] = None

    for raw in docblock.splitlines():
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


def parse_docblock(docblock: str, func_name: str, signature: str, return_type: str) -> FunctionDoc:
    doc = FunctionDoc(name=func_name, signature=signature, return_type=return_type)
    current: Optional[str] = None

    for raw in docblock.splitlines():
        line = strip_doc_prefix(raw)
        stripped = line.strip()

        if not stripped:
            if current == "example":
                doc.example.append("")
            continue

        if stripped.startswith("@function"):
            current = None
            # keep parsed function name from signature as source of truth
        elif stripped.startswith("@brief"):
            doc.brief = stripped[len("@brief"):].strip()
            current = None
        elif stripped.startswith("@details"):
            doc.details = stripped[len("@details"):].strip()
            current = "details"
        elif stripped.startswith("@param"):
            # Format: @param name Type Description...
            parts = stripped.split(maxsplit=3)
            if len(parts) >= 4:
                _, name, type_name, desc = parts
            elif len(parts) == 3:
                _, name, type_name = parts
                desc = ""
            else:
                # malformed @param
                continue
            doc.params.append(ParamDoc(name=name, type_name=type_name, description=desc))
            current = None
        elif stripped.startswith("@returns"):
            rest = stripped[len("@returns"):].strip()
            # Accept either:
            #   @returns DFREF Description...
            #   @returns Description...
            ret_parts = rest.split(maxsplit=1)
            if len(ret_parts) == 2 and ret_parts[0] in {"Variable", "String", "Wave", "DFREF"}:
                doc.return_type = ret_parts[0]
                doc.returns = ret_parts[1]
            else:
                doc.returns = rest
            current = None
        elif stripped.startswith("@note"):
            doc.notes.append(stripped[len("@note"):].strip())
            current = "note"
        elif stripped.startswith("@example"):
            current = "example"
        else:
            if current == "details":
                doc.details += ("\n" if doc.details else "") + stripped
            elif current == "note":
                if doc.notes:
                    doc.notes[-1] += " " + stripped
            elif current == "example":
                # Preserve indentation better for code examples
                doc.example.append(line)

    return doc


def extract_documented_functions(text: str) -> List[FunctionDoc]:
    results: List[FunctionDoc] = []

    for match in DOC_PLUS_FUNC_RE.finditer(text):
        docblock = match.group("doc")
        func_line = match.group("func")

        func_match = FUNC_RE.search(func_line)
        if not func_match:
            continue

        retflag = func_match.group("retflag")
        name = func_match.group("name")
        signature = func_match.group("sig").strip()
        return_type = return_type_from_flag(retflag)

        results.append(parse_docblock(docblock, name, signature, return_type))

    return results


# -----------------------------
# Markdown rendering
# -----------------------------

def render_module_markdown(module_doc: ModuleDoc, functions: List[FunctionDoc]) -> str:
    lines: List[str] = []

    title = markdown_escape(module_doc.name)
    lines.append(f"# {title}")
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

    for fn in functions:
        lines.extend(render_function_markdown(fn))
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def render_function_markdown(fn: FunctionDoc) -> List[str]:
    lines: List[str] = []

    lines.append(f"## `{fn.name}`")
    lines.append("")

    lines.append(f"**Signature**")
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
            type_part = f" *({p.type_name})*" if p.type_name else ""
            desc_part = f": {p.description}" if p.description else ""
            lines.append(f"- `{p.name}`{type_part}{desc_part}")
        lines.append("")

    lines.append("### Returns")
    lines.append("")
    if fn.returns:
        lines.append(f"- **{fn.return_type}**: {fn.returns}")
    else:
        lines.append(f"- **{fn.return_type}**")
    lines.append("")

    if fn.notes:
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


def render_index_markdown(module_names: List[str], title: str = "API Documentation") -> str:
    lines = [
        f"# {title}",
        "",
        "```{toctree}",
        ":maxdepth: 2",
        "",
    ]
    for name in module_names:
        lines.append(f"api/{name}")
    lines.extend(["```", ""])
    return "\n".join(lines)


# -----------------------------
# File processing
# -----------------------------

def process_file(ipf_path: Path, output_dir: Path) -> Optional[str]:
    text = ipf_path.read_text(encoding="utf-8", errors="ignore")
    fallback_module_name = ipf_path.stem

    module_block = extract_module_block(text)
    module_doc = parse_module_doc(module_block, fallback_module_name) if module_block else ModuleDoc(name=fallback_module_name)

    functions = extract_documented_functions(text)

    if not functions and not module_block:
        return None

    out_name = fallback_module_name
    out_path = output_dir / f"{out_name}.md"
    out_path.write_text(render_module_markdown(module_doc, functions), encoding="utf-8")
    return out_name


def build_docs(input_dir: Path, docs_dir: Path) -> None:
    api_dir = docs_dir / "api"
    api_dir.mkdir(parents=True, exist_ok=True)

    module_names: List[str] = []
    for ipf_path in sorted(input_dir.glob("*.ipf")):
        name = process_file(ipf_path, api_dir)
        if name:
            module_names.append(name)

    index_md = docs_dir / "index.md"
    index_md.write_text(render_index_markdown(module_names), encoding="utf-8")


# -----------------------------
# CLI
# -----------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate MyST Markdown API docs from documented Igor Pro .ipf files.")
    parser.add_argument("input_dir", nargs="?", default="igor_src", help="Directory containing .ipf files")
    parser.add_argument("docs_dir", nargs="?", default="docs", help="Sphinx docs source directory")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    docs_dir = Path(args.docs_dir)

    if not input_dir.exists():
        raise SystemExit(f"Input directory does not exist: {input_dir}")

    build_docs(input_dir, docs_dir)
    print(f"Done. Generated MyST Markdown docs in: {docs_dir}")


if __name__ == "__main__":
    main()