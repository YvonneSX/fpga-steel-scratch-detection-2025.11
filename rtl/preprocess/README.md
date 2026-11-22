# Preprocessing stage

This stage is reserved for image-conditioning blocks such as fixed-pattern
correction, denoising, and contrast normalization. The current stream core
converts RGB565 to grayscale before candidate extraction and does not yet
apply additional preprocessing.
