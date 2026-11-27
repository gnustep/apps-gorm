# View icon source

`GormView.png` is the source for `../GormView.tiff`, the 48 × 48 document-viewer
icon. Its teal canvas, graphite bevel, and magenta selection handles echo
Gorm's existing object icons without requiring a text label inside the image.
Transparent padding supports both light and dark themes.

The source was created with OpenAI's built-in image-generation tool. This is
AI-assisted artwork; independent human review is required before acceptance
under the repository's POLICY_AI.md. It replaces the previous View document
sheet icon; no other icons or archived interface resources are changed.

Regenerate the runtime TIFF from the repository root using ImageMagick:

```sh
convert GormCore/Images/Sources/GormView.png -filter Lanczos -resize 48x48 -units PixelsPerInch -density 72 -depth 8 -compress None GormCore/Images/GormView.tiff
```

Generation prompt (transparent background enabled):

> Create ONE production desktop application icon for GNUstep Gorm representing a standalone editable VIEW / canvas, not a window and not a document sheet. Transparent background. Square composition, centered, generous 6% transparent padding. Must remain exceptionally clear at 48 x 48 pixels: few large simple shapes, no fine details, absolutely no text, letters, numbers, title bar, window buttons, pencil or cursor. A slightly perspective-tilted upright rectangular teal-green canvas with a thick dark graphite beveled rim, subtle sculpted 1990s NeXT / early desktop 3D shading. Four vivid magenta square selection handles at its four corners clearly communicate editable view. Inside the teal canvas two simple inset pale mint geometric UI blocks (a broad horizontal bar and a square) add a little composition without clutter. Magenta and teal echo Gorm's classic purple/magenta and green object icons. Restrained highlights, sharp clean silhouette, avoid glossy app-store rounded-square badges, avoid glow or blur or heavy drop shadow. Whole canvas occupies most of image and no background scene. Deliver a single standalone icon, no presentation sheet or variants.
