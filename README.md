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
photopack [options] {pack|unpack} <source> <destination>
```

####Pack

Pack command accepts a folder full of photos as a source. It then packs them into a "mp4" file, provided as the destination.
The optional -r (recursive) will descend into subfolders from the source looking for images also.

####Unpack

Unpack command accepts an mp4 file as input. It then extracts all images into the provided folder destination.

### Compile Project

To compile all files with gulp, simply run gulp in the project, or run the below:

```
npm install && npm run build
```
