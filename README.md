![Cover_photo_GitHb](https://user-images.githubusercontent.com/79197303/208967141-67cd922e-c4d5-476e-98f8-f6c60870df0e.png)


# A pipeline based on open source deep learning tools for reliable analysis of complex 3D images of Medaka ovaries

Associated publication : https://doi.org/10.1101/2022.08.03.502611



The pipeline is designed for biologists to allow utilization of <b>pre-trained deep-learning model Cellpose</b> for segmentation of <b>3D images of ovaries</b> (or other round objects).

- It avoids need for an extensive 3D annotation and training with specialized data.
- It enables segmentation and analysis of large size range of follicles (from 20um to >1200 um)
- It works with either cytoplasmic fluorescent signal or contour staining of follicles.
- It has been tested on Medaka, Trout and Zebrafish ovaries acquired by confocal microscopy.


<b>The pipeline contains mostly open source tools (Fiji, Cellpose)
  
  We also provide a complete Fiji macro tool for image processing (CLIP : Combine_Labels_and_Image_Pre_Processing).</b> It contains only open source tools for image registration, image enhancement and segmentation image post-processing and quantitative analysis.
 
 

# CLIP_Combine_Labels_and_Image_Pre_Processing :

   - CLIP_Image Menu : Pre-processing steps are developed for 3D image stacks to improve visualization and the segmentation process by Cellpose, especially for heterogeneous fluorescent staining. 

  - CLIP_Labels Menu : Post-processing steps are developed for correction of segmentation results and to solve Cellpose issue for segmentation of a large variety of objects size (i.e 20um to 1200um in diameter for medaka ovaries). 





![Cover_photo_GitHub](https://user-images.githubusercontent.com/79197303/208967238-196c27d2-482f-4c49-9421-57921ff9d63c.png)



