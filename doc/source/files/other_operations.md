
# Useful operations

## Photoemission database

Athina has a built in database for photelectron cross-sections and electron binding energies (core and Auger levels). You can launch the interface to the database from **athina > Utilities > Photoemission database**

Using the database is straighforward: 

select the elements you want to check in the periodic table, the energy window to search for core and/or Auger energy levels (Emin & Emax), the photon energy (hv) and if you want the results in Kinetic (KE) or Binding energy (BE), then press "Show".\
By default both photoelectrons (Photo) and Auger electrons (Auger) are reported, you can untick the selection if you want different
behaviour. Photoionisation cross-sections are not plotted by default for the selected elements, you have to tick the selection (Cross Sections).


```{figure} media/photoemissiondatabase.png
:alt: Photoemission database
:scale: 33%
:align: center
:name: photoemissiondatabase

Photoemission database: 1: Show data for selected elements, 2: Set energy windows to search for energy levels, 
3: Set photon energy and sample's work function, 4: Select whether to report Core Levels (Photo) and/or 
Auger peaks (Auger), 5: Toggle BE or KE scale, 6: Show photoionisation cross-sections, 7: Clear selection 
and close all database windows, 8: Set scaling of the panel.
```

```{tip} 

If you do not select any elements in the periodic table and press "Show" the database will give you all peaks that fall in the selected energy window. 

If you select a photon energy *hv less than the wf* of your sample and the energy mode is set to BE (binding energy) then all core levels of the selected atom(s) will be shown (or all core levels of all atoms if nothing is selected in the periodic table)
```

```{Note} 
Data for the core levels are taken from *[X-ray data booklet](https://xdb.lbl.gov)*.\
Data for the Auger peaks are compiled from the *[Handbook of X-ray Photoelectron Spectroscopy](https://data.bris.ac.uk/datasets/q5hfkppqacnh2wbxkpa5t5r51/Experimental/xps_handbook.pdf)*.\
Data for the photoemission cross-sections are taken from *[J. J. Yeh and I.Lindau, Atomic Data and Nuclear Data Tables, 32, 1-155 (1985)](https://www.sciencedirect.com/science/article/pii/0092640X85900166)*.
```
## Measure distances

