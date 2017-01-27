# Photopack

Pack a series of photos (jpeg) into a h265 video file.

### Installation

Install NodeJS https://nodejs.org

Run the following command.

```
npm install photopack -g
```

### Usage

```
photopack [pack|unpack] Source Destination
```

####Pack

Pack command accepts a folder or an image as source. If a folder, it grabs all jpegs in the folder. It then packs them into a "mp4" file, provided as the destination (and creates a corresponding .index file).

####Unpack

Unpack command accepts an mp4 file as input. If a .index file of the same name is in the same folder it'll be used for image metadata. It then extracts all images into the provided folder destination.

### Compile Project

To compile all files with gulp, simply run gulp in the project, or run the below:

```
npm run build
```
