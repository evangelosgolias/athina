
# How-to guides

## XAS, LEEM-IV & LEED-IV

Use the [z-profiler](operations.md#z-profile) to extract information from XAS, LEEM-IV and LEED-IV data.

## XMCD/XMLD

There are two ways to calculate the XMLD/XMCD.

### Standard


**A:** You need a stack with the two images to calculate the XMLD/XMCD. To create the stack select the two images in the data browser, right click and "Make stack and display".

Use the slider to check if the two images are aligned. If there is a drift correct it (see [Drift Correction](operations.md#drift-correction)). Then right click on the image and press "ATH Calculate XMC(L)D (3D[2])".

**B:** You can use the menu entry "athina > XMC(L)D calculation > XMC(L)D (2D[2]) ...". A new data browser will pop to select two images to calculate the XMCD. 
*N.B You have to be sure that the images are aligned!*

### Interactive 

You can use an interactive interface to calculate the XMCD/XMLD and correct image drifts interactively using the arrow keys. Selecte "athina > Interactive operations > XMC(L)D calculation ...". A data browser will appear and you have to select two image. The new dialog will ask you to select the image order and give you a hint on how the dicroism will be calculated. 

You will then see thw following interface. The image on the right it's the calculated XMC(L)D = (img1-img2)/(img1 + img2). On the left you can see the sum of the two images img1 + img2 (note the graph titles!). Use the arrow keys to correct the drift, **the right image has to be the the top graph, otherwise the arrow keys will have no effect!**.

You can set in the "Drift step (px)" box how many pixels per keystroke you'd like the image to move, sub-pixel or non-integer pixels are allowed. If you press the button "Restore" you start over, and if you press "Save XMCD" the current XMCD/XMLD image will be saved.

```{figure} media/interactive_xmcd.png
:alt: interactive xmcd
:scale: 33%
:align: center
:name: iXMCD

Interactive calculation of XMCD/XMLD. Use arrow keys to move one image with respect to the other to correct the drift.
```
```{Note} 
There is a counter that accumulates the total drift correction along x and y based on the total number of keystrokes and step sizes, then the original image is moved once to minimize aliasing effects. An affine transformation is used for the drift correction.
```

## XPS/PES

XPS/PES datasets are saved as images of the dispersive plane (DP). To extract the spectrum from the image you need to know the energy scale of the image, i.e. how many eV correspond to one pixel. To calculate this you need either need spin-orbit split core level (e.g. Au 4f) witn known separation between the two peaks or simpler just save two images of the DP with 1V difference in start voltage for a core level of your sample. 
You can take two line profiles (use the athina's [line profile](operations.md#line-profile) funtion) and calculate how many pixels your peak moved with Δstv = 1 V. Then your conversion factor is: 1/Δpx, Δpx is the pixel difference. You have to put this value, named EPP factor (energy per pixel), to the box and press enter. EPP shouldn't change as long as you do not change the microscope settings.

```{Note} 
At the moment the photon energy (hv) is read from the filename of the image. If the program fails to read it you have to enter it. STV is read from the image metadata and the Wf is your sample's work function (arbitrary (reasonable) number).
```

Now you have to place the markers, A & B (green marker, see the image below), so that the program finds the middle of the DP (under normal conditions that should be the value of STV). Place the markers exactly at the edges of the DP (you can zoom in and out) and press the button "Set Csr A & B", which will turn green.

```{figure} media/setDPLineiXPS.png
:alt: Set DP line in PES mode
:scale: 33%
:align: center
:name: setDPLine

Set markers A, B at the edges of the dispersive plane and press "Press Csr A & B"
```

Now you can move the cursors E and F and see the profile interactively (see image below)

```{Caution} 
Cursors E and F have colors to indicate the region where they should move. Cursor E should be closer to the low kinetic energy side of the DP. There are colors on the image to help the user place the cursors correctly. The light green dashed line in the position of the calculated STV (middle point of the perpendicular line connecting the red and blue dashed line.)
```

The bottons, tickboxes of the panel do the following:

- Save Profile: Saves the current spectrum-
- Save Settings: Save all settings (not STV, hv) and restore.
- Restore settings: Restore saved settings (if they exists the "Save settings" button will be green).
- Show width: Show set line profile integration width while pressed.
- Plot Profile: Display the saved spectrum.
- Show BE: Show spectrum in BE scale.
- Stack layer: Update displayed spectrum when displayed plane changes in a 3D wave.
- Width: integration with of the extraction profile in pixels.

```{figure} media/extractXPSProfile.png
:alt: Extract an XPS profile
:scale: 33%
:align: center
:name: extractXPS

Interactive XPS in action
```

## PED/ARPES

See the section about how to extract a [plane profile](operations.md#plane-profile).