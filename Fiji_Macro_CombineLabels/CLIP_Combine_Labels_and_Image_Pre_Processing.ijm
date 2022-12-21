// Macros CLIP Combine Labels and Images Pre Processing
// V1.0 le 13-11-22
// Written by Violette THERMES, Manon LESAGE - INRAE LPGP
// Part of the DYNAMO project

/////////////////////// INFOS ////////////////////////////
// These macros for combining 3D labels from different segmentation runs, as for Cellpose segmentation (with adjusted image resolution and/or diameter parameter)
// This file contains two parts, one part contains macros for Image Pre-treatment and one part contains macros for Labels Post-Treatment.

//////////////////// DEPENDENCIES ///////////////////////
// - CLIJ2 plugin for GPU-assisted operations
// - MorphoLibJ plugin
//  A COMPLETER _____

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
// first release date: 13/11/2022
// latest release date: 13/11/2022
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

/*
 *	Copyright (C), Violette Thermes and Mand LEsage / BioVoxxel. All rights reserved.
 *
 *	All Macros were written by Manon Lesage é Violette Thermes.
 *
 *	Redistribution and use in source and binary forms of all macros, with or without modification, 
 *	are permitted provided that the following conditions are met:
 *
 *	1.) Redistributions of source code must retain the above copyright notice, 
 *	this list of conditions and the following disclaimer.
 *	2.) Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
 *	and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  3.) Neither the name of BioVoxxel nor the names of its contributors may be used to endorse or promote 
 *  products derived from this software without specific prior written permission.
 *	
 *	DISCLAIMER:
 *
 *	THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ?AS IS? AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 *	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *	DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *	SERVICES;  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 *	USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------------------------------------------//
//------------------------------------   CLIP_Image (Image Pre-processing) ------------------------------------------//
//-------------------------------------------------------------------------------------------------------------------//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// CLIP_Image Macro Menu

	var filemenu = newMenu("CLIP_Image Menu Tool", 
	newArray("CONTRAST N2V EDGE", "CONTRAST EDGE N2V", "-", 
	"Step By Step", "-", "-", "About"));
	
	macro "CLIP_Image Menu Tool - icon:image.png"{
		CLIPCmd = getArgument();
		if (CLIPCmd!="-") {
			if (CLIPCmd=="CONTRAST N2V EDGE") { CLAHE_N2V_EDGE(); }
			else if (CLIPCmd=="CONTRAST EDGE N2V") { CLAHE_EDGE_N2V(); }
			else if (CLIPCmd=="Step By Step") { StepByStep(); }
			else if (CLIPCmd=="About") { About(); }
				}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "C N2V E Action Tool - icon:C_N2V_E.png" {
// The macro C-N2V-E (CLAHE, N2V, Edge) improves the signal (signal to noise ratio) before Cellpose segmentation.
// High contrast, noise reduction (N2V) and Edge enhancment.

function CLAHE_N2V_EDGE() { 
NameMacro="CONTRAST_N2V_EDGE";
Initialization();

setBatchMode(true);

//File directories 
dir = getDirectory("Where is the file containing your image(s)?");
File.makeDirectory(dir+"\\CONTRAST_N2V_EDGE\\");
subdir = dir+"\\CONTRAST_N2V_EDGE\\";

File.makeDirectory(subdir+"\\01-CONTRAST\\");
outputdirC = subdir + "\\01-CONTRAST\\";
File.makeDirectory(subdir+"\\02-N2V\\");
outputdirN2V = subdir + "\\02-N2V\\";
File.makeDirectory(subdir+"\\03-EDGE\\");
outputdirE = subdir +"\\03-EDGE\\";
File.makeDirectory(subdir+"\\04-DOWNSCALE\\");
outputdirD = subdir + "\\04-DOWNSCALE\\";

// Settings parameters and dependencies
showMessage("WARNING", "Place your N2V model in a folder (1 model = 1 folder)"+
"\n-----Press Ok to choose the N2V model folder");
ModelLocation = getDirectory("Where is your N2V model folder?");
	count = 1;
    list = getFileList(ModelLocation);
    for (i=0; i<list.length; i++) {
        if (endsWith(list[i], "/"))
           listFiles(""+ModelLocation+list[i]);
           name= File.getNameWithoutExtension(ModelLocation+list[i]);
     	}

//Parameters //
html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<b>CLAHE</b> : "
     +"Enhance local contrasts and helps fluorescent signal recovery, signal homogenization."
     +"<b>Maximum slope</b> defines amplitude of histogram equalization.</b><br>"
     +"<br> <b>N2V</b> : "
     +"Performs image denoising from neural network prediction."
     +"A <b>trained bioimage.io model</b> is needed to perform this step.<br>"
     +"<br><b>Edge</b> : "
     +"External gradient is subtracted from image, resulting in <b>darker external borders</b> of objects (Edge_border)."+
     " Internal gradient can also be added on image, resulting in <b>brighter signal of features</b> (Edge_border&cyto).<br>"
     +"<br><b>Downscaling</b> : "
     +"Prepare a downscaled image for segmentation of largest objects poorly segmented in best image resolution</b> images<br>"
     +"</font>"
     +"</html>";
     
Dialog.create("Adjust parameters");
Dialog.addMessage("------ CONTRAST (CLAHE method):");
Dialog.addNumber("Block size", 512,0,3,"pixel");
Dialog.addNumber("histogram_bins", 255);
Dialog.addNumber("Maximum slope", 6, 0, 2, "");
Dialog.addMessage("Block size : should be larger than the size of features to be preserved"+
"\nMaximum slope : = 1 (original image);"+
" = 1.5-6 (correct signal);"+
"\n                                = 30 (very low & heterogenous signal)",11);
Dialog.addMessage("------ N2V model (Name of your model file, without .zip extension):");
Dialog.addString("Name:", name);
Dialog.addMessage("------ EDGE (highlight features boundaries) :");
items=newArray("Edge_border", "Edge_border&cyto");
Dialog.addChoice("Choose method", items, "Edge_border");
Dialog.addMessage("------ DOWNSCALING image :");
Dialog.addMessage("Adjust pixel size for further detection of large objects with Cellpose", 11);
Dialog.addNumber("Factor X", 2);
Dialog.addNumber("Factor Y", 2);
Dialog.addNumber("Factor Z", 2);
Dialog.addHelp(html);
Dialog.show();

//paramaters values
blocksize = Dialog.getNumber();
histogram_bins = Dialog.getNumber();
maximum_slope = Dialog.getNumber();
modelname = Dialog.getString();
choice = Dialog.getChoice();
X = Dialog.getNumber();
Y = Dialog.getNumber();
Z = Dialog.getNumber();
mask = "*None*";
fast = true;
process_as_composite = false;

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

///////////////////////////////////  CONTRAST  /////////////////////////////////////
input= dir;
filelistC= getFileList(input);
output= outputdirC;

for (i=0; i < lengthOf(filelistC); i++){
    if((endsWith(filelistC[i], ".tif") || (endsWith(filelistC[i], ".TIF")))){
print("............................................................");
print("...[ File ]...: "+filelistC[i]);
        	run("Close All");
       		run("Clear Results");
   		open(input + File.separator + filelistC[i]);
       		filename = getTitle();
			filename = replace(filename, ".tif", "");
			GetImageInfo();
			
		//CLAHE on STACK
			CLAHEonStack();
	    	rename(filename + "_CLAHE");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
	   	saveAs("tiff", output + FileResult);
print("......[ "+FileResult+" ]   saved in : "+output+"");
    }}

setBatchMode(false);

////////////////////////////////////////// N2V //////////////////////////////////////
input= outputdirC;
filelistN2V= getFileList(input);
output= outputdirN2V;

for (i=0; i < lengthOf(filelistN2V); i++){
    if((endsWith(filelistN2V[i], ".tif") || (endsWith(filelistN2V[i], ".TIF")))){
print("............................................................");
print("...[ File ]...: "+filelistN2V[i]);
      		run("Close All");
       		run("Clear Results");
   		open(input + File.separator + filelistN2V[i]);
   		GetImageInfo();
       		filename = getTitle();
			filename = replace(filename, ".tif", "");
       		InputImage= input + filename + ".tif";

		//Run N2V
			N2V();	    	
	    	rename(filename + "_N2V");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
    	saveAs("Tiff", output + FileResult);
print("......[ "+FileResult+" ] saved in : "+output+"");
   }}
//////////////////////////////// EDGE AND Downscaling //////////////////////////////
setBatchMode(true);
input= outputdirN2V;
filelistEDGE= getFileList(input);
output= outputdirE;

for (i=0; i < lengthOf(filelistEDGE); i++){
    if((endsWith(filelistEDGE[i], ".tif") || (endsWith(filelistEDGE[i], ".TIF")))){
print("............................................................");
print("...[ File ]...: "+filelistEDGE[i]);
      		run("Close All");
       		run("Clear Results");
       	open(input + File.separator + filelistEDGE[i]);
       	GetImageInfo();
       		filename_tif= getTitle();
       		filename= replace(filename_tif, ".tif", "");
       		
		//Run Edges substraction with Morphological gradient (MorphoLibJ)
			Edge();
	    	rename(filename + "_EDGE");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
	   	saveAs("tiff", output + FileResult);
print("......[ "+FileResult+" ]   saved in : "+output+"");

		//Run Downscaling
output= outputdirD;
print("............................................................");
print("[ Downscaling parameters ]...: Factor X="+X, " ; Factor Y="+Y, " ; Factor Z="+Z);
print(".........[ Pixel size before downscaling ]...:");	
			GetImageInfo();
			Downscaling();
	    	rename(FileResult + "_RES");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
		saveAs("Tiff", output + FileResult);
print("......[ "+FileResult+" ] saved in : "+output+"");
   }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------" );
ID="Auto";
RepResultat=subdir;
Save_infos(ID);
selectWindow("W&L");
run("Close");
Ending_macro();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "CE N2V Action Tool - icon:CE_N2V.png" {
// The macro CE-N2V (CLAHE, Edge, N2V) improves the signal (signal to noise ratio) before Cellpose segmentation.
// High contrast, Edge enhancment and noise reduction (N2V).


function CLAHE_EDGE_N2V() { 
NameMacro="CONTRAST_EDGE_N2V";
Initialization();

setBatchMode(true);

//File directories 
dir = getDirectory("Where is the file containing your image(s)?");
File.makeDirectory(dir+"\\CONTRAST_EDGE_N2V\\");
subdir = dir+"\\CONTRAST_EDGE_N2V\\";

File.makeDirectory(subdir+"\\01-CONTRAST\\");
outputdirC = subdir + "\\01-CONTRAST\\";
File.makeDirectory(subdir+"\\02-EDGE\\");
outputdirE = subdir +"\\02-EDGE\\";
File.makeDirectory(subdir+"\\03-N2V\\");
outputdirN2V = subdir + "\\03-N2V\\";
File.makeDirectory(subdir+"\\04-DOWNSCALE\\");
outputdirD = subdir + "\\04-DOWNSCALE\\";



// Parameters
showMessage("WARNING", "Place your N2V model in a folder (1 model = 1 folder)"+
"\n-----Press Ok to choose the N2V model folder");
ModelLocation = getDirectory("Where is your N2V model folder?");
	count = 1;
    list = getFileList(ModelLocation);
    for (i=0; i<list.length; i++) {
        if (endsWith(list[i], "/"))
           listFiles(""+ModelLocation+list[i]);
           name= File.getNameWithoutExtension(ModelLocation+list[i]);
     	}

html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<b>CLAHE</b> : "
     +"Enhance local contrasts and helps fluorescent signal recovery, signal homogenization."
     +"<b>Maximum slope</b> defines amplitude of histogram equalization.</b><br>"
     +"<br><b>Edge</b> : "
     +"External gradient is subtracted from image, resulting in <b>darker external borders</b> of objects (Edge_border)."+
     " Internal gradient can also be added on image, resulting in <b>brighter signal of features</b> (Edge_border&cyto).<br>"
     +"<br> <b>N2V</b> : "
     +"Performs image denoising from neural network prediction."
     +"A <b>trained bioimage.io model</b> is needed to perform this step.<br>"
     +"<br><b>Downscaling</b> : "
     +"Prepare a downscaled image for segmentation of largest objects poorly segmented in best image resolution</b> images<br>"
     +"</font>"
     +"</html>";
     
Dialog.create("Adjust parameters");
Dialog.addMessage("------ CONTRAST (CLAHE method):");
Dialog.addNumber("Block size", 512,0,3,"pixel");
Dialog.addNumber("histogram_bins", 255);
Dialog.addNumber("Maximum slope", 6, 0, 2, "");
Dialog.addMessage("Block size : should be larger than the size of features to be preserved"+
"\nMaximum slope : = 1 (original image);"+
" = 1.5-6 (correct signal);"+
"\n                                = 30 (very low & heterogenous signal)",11);
Dialog.addMessage("------ EDGE (highlight features boundaries) :");
items=newArray("Edge_border", "Edge_border&cyto");
Dialog.addChoice("Choose method", items, "Edge_border");
Dialog.addMessage("------ N2V model (Name of your model file, without .zip extension):");
Dialog.addString("Name:", name);
Dialog.addMessage("------ DOWNSCALING image :");
Dialog.addMessage("Adjust pixel size for further detection of large objects with Cellpose", 11);
Dialog.addNumber("Factor X", 2);
Dialog.addNumber("Factor Y", 2);
Dialog.addNumber("Factor Z", 2);
Dialog.addHelp(html);
Dialog.show();

//parameters values
blocksize = Dialog.getNumber();
histogram_bins = Dialog.getNumber();
maximum_slope = Dialog.getNumber();
choice = Dialog.getChoice();
modelname = Dialog.getString();
X = Dialog.getNumber();
Y = Dialog.getNumber();
Z = Dialog.getNumber();
mask = "*None*";
fast = true;
process_as_composite = false;

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

///////////////////////////////////  CONTRAST  /////////////////////////////////////
input= dir;
filelistC= getFileList(input);
output= outputdirC;

for (i=0; i < lengthOf(filelistC); i++){
    if((endsWith(filelistC[i], ".tif") || (endsWith(filelistC[i], ".TIF")))){
print("...[ File ]...: "+filelistC[i]);
        	run("Close All");
       		run("Clear Results");
   		open(input + File.separator + filelistC[i]);
       		filename = getTitle();
			filename = replace(filename, ".tif", "");
			GetImageInfo();
			
		//CLAHE on STACK
			CLAHEonStack();
	    	rename(filename + "_CLAHE");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
	   	saveAs("tiff", output + FileResult);
print("......[ "+FileResult+" ]   saved in : "+output+"");
    }}

///////////////////////////////////  EDGE  /////////////////////////////////////
input= outputdirC;
filelistEDGE= getFileList(input);
output= outputdirE;

for (i=0; i < lengthOf(filelistEDGE); i++){
    if((endsWith(filelistEDGE[i], ".tif") || (endsWith(filelistEDGE[i], ".TIF")))){
print("...[ File ]...: "+filelistEDGE[i]);
      		run("Close All");
       		run("Clear Results");
       	open(input + File.separator + filelistEDGE[i]);
       	GetImageInfo();
       		filename_tif= getTitle();
       		filename= replace(filename_tif, ".tif", "");
       		
		//Run Edges substraction with Morphological gradient (MorphoLibJ)
			Edge();
	    	rename(filename + "_EDGE");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
	   	saveAs("tiff", output + FileResult);
print("......[ "+FileResult+" ]   saved in : "+output+"");
    }}
setBatchMode(false);

//////////////////////////////// N2V AND Downscaling //////////////////////////////

filelistN2V= getFileList(outputdirE);
input= outputdirE;
output= outputdirN2V;

for (i=0; i < lengthOf(filelistN2V); i++){
    if((endsWith(filelistN2V[i], ".tif") || (endsWith(filelistN2V[i], ".TIF")))){   	
print("...[ File ]...: "+filelistN2V[i]);
      		run("Close All");
       		run("Clear Results");
       		open(input + File.separator + filelistN2V[i]);
       		filename = getTitle();
			filename = replace(filename, ".tif", "");
       		InputImage= input + filename + ".tif";
	
		//Run N2V
			N2V();
    	   	rename(filename + "_N2V");
    	   	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
    	    saveAs("Tiff", output + FileResult);
print("......[ "+FileResult+" ] saved in : "+output+"");

		//Run Downscaling
			filename= getTitle();
			output=outputdirD;
print("[ Downscaling parameters ]...: Factor X="+X, " ; Factor Y="+Y, " ; Factor Z="+Z);
print(".........[ Pixel size before downscaling ]...:");	
			GetImageInfo();  
			Downscaling();
			rename(filename + "_RES");
	    	FileResult_tif=getTitle();
	    	FileResult=replace(FileResult_tif, ".tif", "");
			saveAs("Tiff", output + FileResult);
print("......[ "+FileResult+" ] saved in : "+output+"");
   }}
   
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------");
ID="Auto";
RepResultat=subdir;
Save_infos(ID);
Ending_macro();
selectWindow("W&L");
run("Close");
close("*");
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "Step by Step Action Tool - icon:StepByStepImage.png" {
	
function StepByStep() { 

//Choose the action 
Dialog.create("Step-By-Step");
items = newArray("Contrast", "Edge", "N2V", "Downscaling");
Dialog.addRadioButtonGroup("What do you want to do? ", items, 4, 1, "");
Dialog.show();
choice = Dialog.getRadioButton();

//Main file directory
dir = getDirectory("Where is the folder containing your image(s)?");
File.makeDirectory(dir+"\\Step_by_step\\");
subdir = dir+"\\Step_by_step\\";


/////////////////////////
if (choice=="Contrast") {
NameMacro="StepByStep_CONTRAST";
Initialization();

setBatchMode(true);

File.makeDirectory(subdir+"\\CONTRAST\\");
output= subdir + "\\CONTRAST\\";
RepResultat=output;

//Parameters
html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<b>CLAHE</b> : "
     +"Enhance local contrasts and helps fluorescent signal recovery, signal homogenization."
     +"<b>Maximum slope</b> defines amplitude of histogram equalization.</b><br>"
     +"</font>"
     +"</html>";
Dialog.create("Adjust parameters");
Dialog.addMessage("------ CONTRAST (CLAHE method):");
Dialog.addNumber("Block size", 512,0,3,"pixel");
Dialog.addNumber("Histogram bins", 255);
Dialog.addNumber("Maximum slope", 6, 0, 2, "");
Dialog.addMessage("Block size : should be larger than the size of features to be preserved"+
"\nMaximum slope : = 1 (original image);"+
" = 1.5-6 (correct signal);"+
"\n                                = 30 (very low & heterogenous signal)");
Dialog.addHelp(html);
Dialog.show();

//parameters values
blocksize= Dialog.getNumber();;
histogram_bins = Dialog.getNumber();;
maximum_slope = Dialog.getNumber();
mask = "*None*";
fast = true;
process_as_composite = false;

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());
print("[ Parameters ]...: Block size="+blocksize, " ; Histogram bins="+histogram_bins, " ; Maximum slope="+maximum_slope);

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF")))){
    	print("...[ File ]...: "+filelist[i]);
        	run("Close All");
       		run("Clear Results");
       		open(dir + File.separator + filelist[i]);
       		filename = getTitle();
			filename = replace(filename, ".tif", "");
			CLAHEonStack();
	   		rename(filename + "_CLAHE");
	   		FileResult_tif=getTitle();
	   		FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("tiff", output + FileResult);
	    print("......[ "+FileResult+" ]   saved in : "+output+"");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time" +ElapsedTime(Start,End)+"]----------"); 
ID="01";
Save_infos(ID);
close("*");
}

/////////////////////
if (choice=="Edge") {
NameMacro="StepByStep_EDGE";
Initialization();

setBatchMode(true);
//dir
File.makeDirectory(subdir+"\\EDGE\\");
output= subdir + "\\EDGE\\";
RepResultat=output;

//parameters
html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<br><b>Edge</b> : "
     +"External gradient is subtracted from image, resulting in <b>darker external borders</b> of objects (Edge_border)."+
     " Internal gradient can also be added on image, resulting in <b>brighter signal of features</b> (Edge_border&cyto).<br>"
     +"</font>"
     +"</html>";
     
Dialog.create("Choose method");
Dialog.addMessage("------ EDGE (highlight features boundaries) :");
items=newArray("Edge_border", "Edge_border&cyto");
Dialog.addChoice("Choose method", items, "Edge_border");
Dialog.addHelp(html);
Dialog.show();

//parameter value
choice = Dialog.getChoice();

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF")))){
    	print("...[ File ]...: "+filelist[i]);
        	run("Close All");
       		run("Clear Results");
       		open(dir + File.separator + filelist[i]);
       		filename_tif = getTitle();
			filename = replace(filename_tif, ".tif", "");
			Edge();
	   		rename(filename + "_EDGE");
	   		FileResult_tif=getTitle();
	   		FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("tiff", output + FileResult);	   		
	    print("......[ "+FileResult+" ]   saved in : "+output+"");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------"); 
ElapsedTime(Start,End);
ID="02";
Save_infos(ID);
close("*");
}

//////////////////////////////////
if (choice=="N2V") {
NameMacro="StepByStep_N2V";
Initialization();

File.makeDirectory(subdir+"\\N2V\\");
output= subdir + "\\N2V\\";
RepResultat=output;

//Parameters
showMessage("WARNING", "Place your N2V model in a folder (1 model = 1 folder)"+
"\n-----Press Ok to choose the N2V model folder");
ModelLocation = getDirectory("Where is your N2V model folder?");
	count = 1;
    list = getFileList(ModelLocation);
    for (i=0; i<list.length; i++) {
        if (endsWith(list[i], "/"))
           listFiles(""+ModelLocation+list[i]);
           name= File.getNameWithoutExtension(ModelLocation+list[i]);
     	}
     	
html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<br> <b>N2V</b> : "
     +"Performs image denoising from neural network prediction."
     +"A <b>trained bioimage.io model</b> is needed to perform this step.<br>"
     +"</font>"
     +"</html>";
Dialog.create("Adjust parameters");
Dialog.addMessage("------ N2V model (Name of your model file, without .zip extension):");
Dialog.addString("Name:", name);
Dialog.addHelp(html);
Dialog.show();

modelname = Dialog.getString();

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

print("[ Parameters ]...: Model name="+modelname);

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF")))){
    	print("...[ File ]...: "+filelist[i]);
        	run("Close All");
       		run("Clear Results");
       		open(dir + File.separator + filelist[i]);
       		filename_tif = getTitle();
			filename = replace(filename_tif, ".tif", "");
			InputImage= dir + filename + ".tif";
			N2V();
	   		rename(filename + "_N2V");
	   		FileResult_tif=getTitle();
	   		FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("tiff", output + FileResult);	   		
	    print("......[ "+FileResult+" ]   saved in : "+output+"");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------"); 
ID="03";
Save_infos(ID);
Ending_macro();
selectWindow("W&L");
run("Close");
close("*");
}

////////////////////////////
if (choice=="Downscaling") {
NameMacro="StepByStep_DOWNSCALING";
Initialization();

setBatchMode(true);

File.makeDirectory(subdir+"\\DOWNSCALING\\");
output= subdir + "\\DOWNSCALING\\";
RepResultat=output;

// Parameters
html = "<html>	See more information here : "+
"<a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Called functions</h2>"
     +"<br><b>Downscaling</b> : "
     +"Prepare a downscaled image for segmentation of largest objects poorly segmented in best image resolution</b> images<br>"
     +"</font>"
     +"</html>";
Dialog.create("Adjust parameters");
Dialog.addMessage("------ DOWNSCALING image :");
Dialog.addMessage("Adjust pixel size for further detection of large objects with Cellpose", 11);
Dialog.addNumber("Factor X", 2);
Dialog.addNumber("Factor Y", 2);
Dialog.addNumber("Factor Z", 2);
Dialog.addHelp(html);
Dialog.show();
X = Dialog.getNumber();
Y = Dialog.getNumber();
Z = Dialog.getNumber();

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

print("[ Downscaling parameters ]...: Factor X="+X, " ; Factor Y="+Y, " ; Factor Z="+Z);

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF")))){
        print("\n [Sample ]....: "+filelist[i]);
            open(dir + File.separator + filelist[i]);
       		filename_tif= getTitle();
			filename= replace(filename_tif, ".tif", "");
	    print(".........[ Pixel size before downscaling ]...:");	
			GetImageInfo();  	       	
			Downscaling();
	   		rename(filename + "_RES");
	   		FileResult_tif=getTitle();
	   		FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("tiff", output + FileResult);
		print("......[ "+FileResult+" ] saved in : "+output+"");
            close();
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------");
ID="04";
Save_infos(ID);
	}	
Ending_macro();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------------------------------------------//
//------------------------------------   CLIP_Labels (Labels Post-processing) ---------------------------------------//
//-------------------------------------------------------------------------------------------------------------------//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// CLIP_Labels Macro Menu

	var filemenu = newMenu("CLIP_Labels Menu Tool", 
	newArray("Combine Labels", "-", "Step By Step", "-", 
	"Add labels manually", "Delete labels manually", "-", "Data extraction", "-", "-", "About"));
	
	macro "CLIP_Labels Menu Tool - icon:Combine.png"{
		CLIPCmd = getArgument();
		if (CLIPCmd!="-") {
			if (CLIPCmd=="Combine Labels") { Combine(); }
			else if (CLIPCmd=="Add labels manually") { AddManually(); }
			else if (CLIPCmd=="Delete labels manually") { DeleteManually(); }
			else if (CLIPCmd=="Step By Step") { StepByStepLabels(); }
			else if (CLIPCmd=="Data extraction") { ExtractData();}
			else if (CLIPCmd=="About") { About(); }
				}
	}
///ADD EXTRACTION DATA, BOUTON OK

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "Combine By Batch All In One Action Tool - icon:Combine.png"{

function Combine() { 
NameMacro="Combine_Labels";
Initialization();

////////////////////// DEFINING FOLDERS, FILES AND PARAMETERS /////////////////////////
			
// INFOS FOLDERS //
html = "<html>"
     +"<h2>Folder organization</h2>"
     //+"<font size=+1>
     +"<b>Pre-processed image</b> :<br>"
     +"\n  Make sure it is the best resolution images used for segmentation<br>"
     +"\n  Images should to be correctly calibrated for <b>voxel size in um</b><br>"
     +"\n  Make sure each image is uniquely identified by a *name_image*<br>"
     +"\n  For batch processing, make sure image resolution is equal for one batch of images<br>"
     +"\n<b>Subfolder \\Small_Masks\\</b> :<br>"
     +"\n  Contains segmentation results obtained with <b>best resolution</b> images<br>"
     +"\n  Segmentation images should have a *name_image* identical to pre-processed image<br>"
     +"\n  Segmentation images should be named as *name_image*_cp_masks.tif<br>"
     +"\n<b>Subfolder \\Large_Masks\\</b> :<br>"
     +"\n  Contains segmentation results obtained with <b>lower resolution</b> images<br>"
     +"\n  Segmentation images should have a *name_image* identical to pre-processed image<br>"
     +"\n  Segmentation images should be named as *name_image*_RES_cp_masks.tif<br>" 
     +"</font>";
  
Dialog.create("Before starting macro");     
Dialog.addMessage("----- Combine Small & Large labels -----"+
"\n       -- Folder organization needed --", 16); 
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=ROOT FOLDER) :"+ 
"\n \n       ....Pre-processed Image  (*name_image*.tif) "+
"\n       ....\\Small_Masks\\    (Subfolder)"+
"\n                      ....*name image*_cp_masks.tif"+
"\n       ....\\Large_Masks\\    (Subfolder)"+
"\n                      ....*name_image*_RES_cp_masks.tif");
Dialog.addMessage("Click OK to select the ROOT FOLDER", 14);
Dialog.addHelp(html);
Dialog.show(); 

//Choose input directory (root folder)
DirImages = getDirectory("Select root folder");

// Subfolder containing  *name image*_cp_masks 
//(best resolution Cellpose segmentation with 30px diameter) :
DirSM = DirImages + "/Small_Masks/"; 
		
// Subfolder containing *name image*_RES_cp_masks 
//(lower resolution Cellpose segmentation with 30 px diameter) :
DirLM = DirImages + "/Large_Masks/";
		
// Output folder :
File.makeDirectory(DirImages + "/Results-Combine/");
RepResultat = DirImages + "/Results-Combine/";

////Choose parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Combine two 3D segmentation results </h2>"
     +"CombineLabels is designed for combination of largest labels from one image with other labels on an image lacking proper segmentation of large follicles.<br>"
     +"<br>Default values corresponds to medaka adult ovary example, with :<br>Image resolution (image data, cp_masks) = 5.41x5.41x6.0002um,  Cellpose 30px<br>Image resolution (RES_cp_masks) = 10.82x10.82x12.0004um,  Cellpose 30px<br>Range of follicles : 20um to 1000-1200um<br>"
     +"<h2>Called functions</h2>"
     +"<b>STEP 1 - Filter small masks</b> : Size and shape filtering process of \"_cp_masks\" image (= Cellpose results from <b>original resolution</b> images).<br>"
     +"- Diameter : Find a value that eliminates poor segmentation labels for smallest objects (False positives). Highly dependent of image resolution.<br>"
     +"- Sphericity : Small follicles are expected to be mostly round, so sphericity is often >0.4, while false positive often have irregular shapes, thus being mostly eliminated. Focus on finding the best value to <b>delete maximum false positive while avoiding loss of true positives.</b><br>"
     +"<br><b>STEP 2 - Filter large masks</b> : Size and shape filtering process of \"RES_cp_masks\" image (= Cellpose results from <b>lower resolution</b> image).<br>" 
     +"- Diameter : Find a value that enables keeping only largest labels that are missing or poorly segmented at STEP 1.<br>"
     +"- Sphericity : Large labels segmented at lower image resolution may present less spherical shapes than small labels. Focus on finding the best value to <b>delete maximum false positives or poorly segmented labels while avoiding loss of true positives.</b><br>"
     +"- Opening : It smooths out labels shape but also slightly reduce their size with each iteration. It should be used carefully, as it highly modifies the spherical shape of labels when highly iterated. <b>Large labels overlap with neighbours (from STEP 1 image) have to be minimized.</b><br>"
     +"<br><b>STEP 3 - Clean over-segmentation before combination</b> : Large labels from STEP 2 are used for detection of regions where over-segmentation needs to be deleted on STEP 1 image. Incorrect labels within or touching those regions are then deleted. <br>"
     +"--Split large masks : Large labels are distributed in 3 different stacks depending on their size range. <b>Erosion factor may need to be higher when labels are larger, choose diameter limits accordingly</b>.<br>"
     +"--Erode Large masks : A label erosion is applied to each split stack. <b>Helps to avoid deletion of neighbours of large labels during combination by avoiding overlap</b>.<br>" 
     +"STEP 3 is tightly linked to STEP 2 -Opening large masks. Higher opening factor at STEP 2 will need smaller erosion factor at STEP 3."
     +"</font></html>";

Dialog.addMessage("            ----- Define parameters for each step -----",16);
Dialog.addMessage("----- STEP 1 : FILTER SMALL MASKS -----   (image \"*_cp_masks\") :", 14);
Dialog.addNumber("Diameter >", 50, 0, 2, "um  (Smaller labels will be deleted)");
Dialog.addNumber("Sphericity >", 0.5, 2, 3,"A value of 1.0 indicates a perfect sphere"); 	
Dialog.addMessage("----- STEP 2 : FILTER AND ADJUST SIZE OF LARGE MASKS -----   (image \"*_RES_cp_masks\") :", 14);			
Dialog.addNumber("   Diameter >", 600, 0, 3, "um   (Select only largest labels needed to be added to image \"*_cp_masks\")"); 
Dialog.addNumber("Sphericity >", 0.25, 2, 3,"A value of 1.0 indicates a perfect sphere");
Dialog.addNumber("Opening", 6, 0, 2,"Factor to adjust shape and size of largest labels");
Dialog.addMessage("----- STEP 3 : CLEAN OVER-SEGMENTATION BEFORE COMBINATION -----", 14)
Dialog.addMessage("  --Split Large masks : \n        This step splits image \"*_RES_cp_masks\" in 3 stacks depending on label size.");
Dialog.addNumber("   Diam1", 600,0,3,"Define size cut-off between stack 1 and 2");
Dialog.addNumber("   Diam2", 750,0,3,"Define size cut-off between stack 2 and 3");
Dialog.addMessage("  --Erode Large masks : \n        This step applies different erosion factors on each stack; largest labels may need higher erosion factor");
Dialog.addNumber("   small", 1, 0,2,"Factor applied on Labels < Diam1  (stack 1)");
Dialog.addNumber("   medium", 4,0,2, "Factor applied on Diam1 < Labels < Diam2  (stack 2)");
Dialog.addNumber("   large", 5,0,2, "Factor applied on Labels > Diam2  (stack 3)");
Dialog.addMessage("----HELP : see Help button for more details about parameters"
+"\n   Default values corresponds to medaka adult ovary example, with :"
     +"\n   Image resolution (image data, cp_masks) = 5.41x5.41x6.0002um,  Cellpose 30px"
     +"\n   Image resolution (RES_cp_masks) = 10.82x10.82x12.0004um,  Cellpose 30px"
     +"\n   Range of follicles : 20um to 1000-1200um",11);
Dialog.addHelp(html);
Dialog.show();
	
// Parameters values
DiamS = Dialog.getNumber();
VolS= 4*(PI*(DiamS/2)*(DiamS/2)*(DiamS/2))/3;
SpherS = Dialog.getNumber();
DiamL = Dialog.getNumber();
VolL= 4*(PI*(DiamL/2)*(DiamL/2)*(DiamL/2))/3;
SpherL = Dialog.getNumber();
Opening= Dialog.getNumber();

Diam1 = Dialog.getNumber();
Diam2= Dialog.getNumber();
ReductionS= Dialog.getNumber();
ReductionM= Dialog.getNumber();
ReductionL= Dialog.getNumber();
Vol1= 4*(PI*(Diam1/2)*(Diam1/2)*(Diam1/2))/3;
Vol2= 4*(PI*(Diam2/2)*(Diam2/2)*(Diam2/2))/3;

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());
print("----------[ CALIBRATION PARAMETERS ]---------- " +
"\n .....Small Diameter min = "+DiamS+", Small Sphericity min = "+SpherS+ 
"\n .....Large Diameter min = "+DiamL+", Large Sphericity min = "+SpherL+ 
"\n .....Large labels Opening = "+Opening+
"\n .....Large labels Erosion = "+ 
"\n .......... Small factor = "+ReductionS+" (labels< "+Diam1+"um)" + 
"\n .......... Medium factor = "+ReductionM+" (labels between "+Diam1+"-"+Diam2+"um)"+ 
"\n .......... Large factor = "+ReductionL+" (labels > "+Diam2+"um)");

print("\n......Results will be saved in : "+RepResultat+"");	
//temporary?

////////////////////// BEGINNING OF THE ANALYSES /////////////////////////						

ListImage = 0;
ListImage = getFileList(DirImages);
print("Files/Folders detected = " + ListImage.length);
nbImage = 0;

for (i=0; i < ListImage.length; i++){
  if((endsWith(ListImage[i], ".tif") || (endsWith(ListImage[i], ".TIF"))) && 
     (!File.exists(RepResultat + File.getNameWithoutExtension(DirImages + 
     ListImage[i])+"_cb_label_filtred.tif"))) {
    if (filter(i, ListImage[i])) {
       setBatchMode(true);
       run("Bio-Formats Windowless Importer", "open=" + DirImages + 
       File.separator + ListImage[i]+" view=Hyperstack stack_order=XYCZT");       		
       NameImagetif=getInfo("image.filename");	
      if(endsWith(NameImagetif, ".tif")) {
         NameImage=replace(NameImagetif, ".tif", ""); }
      if(endsWith(NameImagetif, ".TIF")){
         NameImage=replace(NameImagetif, ".TIF", ""); }
print(".....[ Running ]..: "+NameImage);
		SizeX = getWidth();						
		SizeY = getHeight();
		SizeZ = nSlices;
		getVoxelSize(ResX, ResY, ResZ, µm);
		saveAs("Tiff", RepResultat + NameImage);
		close("*");
print(".....[ Image Resolution ].....: "+ResX+" um x "+ResY+" um x "+ResZ+" um");
				
////CLIP functions////
//corresponding inputs/outputs
dir=DirImages;
output= RepResultat;
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";
//Functions filter	
Filter_Small_masks();
Filter_Large_masks();

Delete_temporary_files();
File.delete(output+"/TEMP/");

//corresponding inputs/outputs
dir=RepResultat;
output=dir;
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";
//Functions for combine
Opening_Large_masks();
Keep_external_labels();
CombineLabels();

print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(dir+"/TEMP/");
//delete others
output= RepResultat;
RepResultat = DirImages + "/Results-Combine/";
filename1=replace(NameImage, "_CLAHE_EDGE_N2V", "");
print(filename1);
File.delete(output+filename1+"_Large&Filtred.tif");
File.delete(output+filename1+"_Small&Filtred.tif");
File.delete(output+filename1+"_Large&Filtred_op.tif");
File.delete(output+filename1+"_Large_erode.tif");
File.delete(output+filename1+"_Small_external.tif");
print("OK");

End=getTime();
print("----------[ "+getInfo("user.name")+", \""+NameImage+"\" was analyzed ]----------"+
"\n----------[ Elapsed time ]----------" + ElapsedTime(Start,End)); 
nbImage++;
}
	    		else {
	        	print(ListImage[i]+ "...Not treated");   
				}
			}
		    else {
		        print("...Not a tiff file");    }
		    }
		    
End=getTime();
print("----------[ END OF MACRO. Elapsed time "+ElapsedTime(Start,End)+" ]----------"); 
ID="Auto";
Save_infos(ID);
Ending_macro();
}

////////////////////// END OF THE MACRO /////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "Step by Step Action Tool - icon:StepByStepLabels.png" {

function StepByStepLabels() { 
// function description
//Choose the action 
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Step_by_step</h2>"
     +"Enables performing each automatic post-processing steps independently. Parameters can be tested, adjusted and validated for each step. It is very useful, and recommended, to begin analysis of new datasets with this Step_by_step function." 
     +"</font></html>";
Dialog.create("Step-By-Step: What do you want to do ?");
items = newArray("YES", "NO");
Dialog.addMessage("----- FILTER AND ADJUST SIZE -----"); 
Dialog.addRadioButtonGroup("STEP 1 : Filter Small masks", items, 1, 2, "NO");
Dialog.addRadioButtonGroup("STEP 2.1 : Filter Large masks", items, 1, 2, "NO");
Dialog.addRadioButtonGroup("STEP 2.2 : Opening Large masks    (Make sure STEP 2.1 have been performed)", items, 1, 2, "NO");
Dialog.addMessage("----- CLEAN AND COMBINE -----"); 
Dialog.addRadioButtonGroup("STEP 3 : Clean over-segmentation    (Make sure STEP 1 & 2 have been performed) :", items, 1,2, "NO");
Dialog.addRadioButtonGroup("STEP 4 : Combine Small&Large    (Make sure STEP 3 have been performed): ", items, 1, 2, "NO");
Dialog.addHelp(html);
Dialog.show();

choice1 = Dialog.getRadioButton();
choice2 = Dialog.getRadioButton();
choice3 = Dialog.getRadioButton();
choice4 = Dialog.getRadioButton();
choice5 = Dialog.getRadioButton();

print("\\Clear");

html_folder = "<html>"
+"<h2>Folder organization</h2>"
+"<b>Pre-processed image</b> :<br>"
+"Make sure it is the best resolution images used for segmentation<br>"
+"Images should to be correctly calibrated for <b>voxel size in um</b><br>"
+"Make sure each image is uniquely identified by a *name_image*<br>"
+"For batch processing, make sure image resolution is equal for one batch of images<br>"
+"<b>Folder \\Small_Masks\\</b> :<br>"
+"Contains Cellpose segmentation results obtained with <b>best resolution</b> images<br>"
+"Segmentation images should have a *name_image* identical to pre-processed image<br>"
+"Segmentation images should be named as *name_image*_cp_masks.tif<br>"
+"<b>Folder \\Large_Masks\\</b> :<br>"
+"Contains Cellpose segmentation results obtained with <b>lower resolution</b> images<br>"
+"Segmentation images should have a *name_image* identical to pre-processed image<br>"
+"Segmentation images should be named as *name_image*_RES_cp_masks.tif<br>" 
+"<b>Folder \\Step_by_step\\</b> :<br>"
+"Contains results of STEP 1 and STEP 2.1 used for next steps (STEP 2.2, 3 and 4)<br>"
+"</font></html>";
//////////////////////////////////
/////////////////////////////
if (choice1=="YES") {
NameMacro="Filter_Small_masks";
Initialization();
setBatchMode(true);


//Main file directory
Dialog.create("Before starting macro");  
Dialog.addMessage("----- STEP 1 : FILTER SMALL MASKS -----\n       -- Folder organization needed --", 16);    
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=ROOT FOLDER) :\n \n       ....Pre-processed Image  (*name_image*.tif) \n       ....\\Small_Masks\\    (Subfolder)\n                      ....*name image*_cp_masks.tif");
Dialog.addMessage("Click OK to select the ROOT FOLDER", 14);
Dialog.addHelp(html_folder);
Dialog.show(); 

dir = getDirectory("SELECT ROOT FOLDER");
DirSM = dir + "/Small_Masks/"; 
DirLM = dir + "/Large_Masks/";

// Output folder :
File.makeDirectory(dir + "/Step_by_step/");
output = dir + "/Step_by_step/";
RepResultat=output;

//TEMP folder
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

//Parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a><br>"
     +"<br><b>STEP 1 - Filter small masks</b> : Size and shape filtering process of \"_cp_masks\" image (= Cellpose results from <b>original resolution</b> images).<br>"
     +"- Diameter : Find a value that eliminates poor segmentation labels for smallest objects (False positives). Highly dependent of image resolution.<br>"
     +"- Sphericity : Small follicles are expected to be mostly round, so sphericity is often >0.4, while false positive often have irregular shapes, thus being mostly eliminated. Focus on finding the best value to <b>delete maximum false positive while avoiding loss of true positives.</b><br>"
     +"</font></html>";
Dialog.addMessage("----- STEP 1 : FILTER SMALL MASKS -----   (image \"*_cp_masks\") :\n",14);
Dialog.addNumber("Diameter >", 50, 0, 2, "um  (Smaller labels will be deleted)");
Dialog.addNumber("Sphericity >", 0.5, 2, 3,"A value of 1.0 indicates a perfect sphere"); 	
Dialog.addHelp(html);
Dialog.show();

//parameters values
DiamS = Dialog.getNumber();
VolS= 4*(PI*(DiamS/2)*(DiamS/2)*(DiamS/2))/3;
SpherS = Dialog.getNumber();

//Starting macro
Filter_Small_masks();

//delete temp
print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");
ID="01";
Save_infos(ID);
}
	
//////////////////////////////////
////////////////////////////
if (choice2=="YES") {
NameMacro="Filter_Large_masks";
Initialization();
setBatchMode(true);

//Main file directory
Dialog.create("Before starting macro");     
Dialog.addMessage("----- STEP 2.1 : FILTER LARGE MASKS -----\n       -- Folder organization needed --", 16); 
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=ROOT FOLDER) :\n \n       ....Pre-processed Image  (*name_image*.tif) \n       ....\\Large_Masks\\    (Subfolder)\n                      ....*name_image*_RES_cp_masks.tif");
Dialog.addMessage("Click OK to select the ROOT FOLDER", 14);
Dialog.addHelp(html_folder);
Dialog.show(); 
dir = getDirectory("SELECT ROOT FOLDER");
DirLM = dir + "/Large_Masks/";

// Output folder :
File.makeDirectory(dir + "/Step_by_step/");
output = dir + "/Step_by_step/";
RepResultat=output;

File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

//Parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<br><br><b>STEP 2.1 - Filter large masks</b> : Size and shape filtering process of \"RES_cp_masks\" image (= Cellpose results from <b>lower resolution</b> image).<br>" 
     +"- Diameter : Find a value that enables keeping only largest labels that are missing or poorly segmented at STEP 1.<br>"
     +"- Sphericity : Large labels segmented at lower image resolution may present less spherical shapes than small labels. Focus on finding the best value to <b>delete maximum false positives or poorly segmented labels while avoiding loss of true positives.</b><br>"
     +"</font></html>";
Dialog.addMessage("----- STEP 2.1 : FILTER LARGE MASKS -----   (image \"*_RES_cp_masks\") :\n",14);			
Dialog.addNumber("   Diameter >", 600, 0, 3, "um   (Select only largest labels needed to be added to image \"*_cp_masks\")"); 
Dialog.addNumber("   Sphericity >", 0.25, 2, 3,"A value of 1.0 indicates a perfect sphere");
Dialog.addHelp(html);
Dialog.show();

//Parameters values
DiamL = Dialog.getNumber();
VolL= 4*(PI*(DiamL/2)*(DiamL/2)*(DiamL/2))/3;
SpherL = Dialog.getNumber();

//Starting macro
Filter_Large_masks();

print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");
ID="02-1";
Save_infos(ID);
}
//////////////////////////////////
////////////////////////////////
if (choice3=="YES") {
// To round up labels
NameMacro="Opening_Large_masks";
Initialization();
setBatchMode(true);

//Main file directory
Dialog.create("Before starting macro");     
Dialog.addMessage("----- STEP 2.2 : ADJUST SIZE OF LARGE MASKS -----\n                 -- Folder organization needed --", 16); 
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=Root folder) :\n \n       ....Pre-processed Image  (*name_image*.tif) \n       ....\\Step_by_step\\   (Subfolder)\n                      ....*name_image*_Large&Filtered.tif" );
Dialog.addMessage("Click OK to select the subfolder  \\Step_by_step\\", 14);
Dialog.addHelp(html_folder);
Dialog.show(); 

//dir folder
dir = getDirectory("SELECT \\Step_by_step\\ FOLDER");
RepResultat=dir;
//TEMP folder
output= RepResultat;
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

//Parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<br><br><b>STEP 2.2 - Opening large masks</b> : Adjust label size of \"RES_cp_masks\" image (= Cellpose results from <b>lower resolution</b> image).<br>" 
     +"- Opening : It smooths out labels shape but also slightly reduce their size with each iteration. It should be used carefully, as it highly modifies the spherical shape of labels when highly iterated. <b>Large labels overlap with neighbours (from STEP 1 image) have to be minimized.</b><br>"
     +"STEP 3 is tightly linked to STEP 2 -Opening large masks. Higher opening factor at STEP 2 will need smaller erosion factor at STEP 3."
     +"</font></html>";
Dialog.addMessage("----- STEP 2.2 : ADJUST SIZE OF LARGE MASKS -----   (image \"*_RES_cp_masks\") :\n",14);			
Dialog.addNumber("Opening", 6, 0, 2,"Factor to adjust shape and size of largest labels");
Dialog.addHelp(html);
Dialog.show();

//Parameters value
Opening= Dialog.getNumber();

//Starting macro
Opening_Large_masks();

print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");
ID="02-2";
Save_infos(ID);
}
//////////////////////////////////
//////////////////////////////////
if (choice4=="YES") {
NameMacro="Keep_external_labels";
Initialization();
setBatchMode(true);

//Main file directory
Dialog.create("Before starting macro");     
Dialog.addMessage("----- STEP 3 : CLEAN OVER-SEGMENTATION BEFORE COMBINATION -----\n                                   -- Folder organization needed --", 16); 
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=Root folder) :\n \n       ....Pre-processed Image  (*name_image*.tif) \n       ....\\Step_by_step\\   (Subfolder)\n                      ....*name_image*_Large&Filtered_op.tif\n                      ....*name_image*_Small&Filtered.tif");
Dialog.addMessage("Click OK to select the subfolder  \\Step_by_step\\", 14);
Dialog.addHelp(html_folder);
Dialog.show(); 

//dir folder
dir = getDirectory("SELECT \\Step_by_step\\ FOLDER");
RepResultat=dir;
//TEMP folder
output= RepResultat;
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

//Parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<br><br><b>STEP 3 - Clean over-segmentation before combination</b> : Large labels from STEP 2 are used for detection of regions where over-segmentation needs to be deleted on STEP 1 image. Incorrect labels within or touching those regions are then deleted. <br>"
     +"--Split large masks : Large labels are distributed in 3 different stacks depending on their size range. <b>Erosion factor may need to be higher when labels are larger, choose diameter limits accordingly</b>.<br>"
     +"--Erode Large masks : A label erosion is applied to each split stack. <b>Helps to avoid deletion of neighbours of large labels during combination by avoiding overlap</b>.<br>" 
     +"STEP 3 is tightly linked to STEP 2 -Opening large masks. Higher opening factor at STEP 2 will need smaller erosion factor at STEP 3."
     +"</font></html>";
Dialog.addMessage("----- STEP 3 : CLEAN OVER-SEGMENTATION BEFORE COMBINATION -----", 14)
Dialog.addMessage("  --Split Large masks : \n        This step splits image \"*_RES_cp_masks\" in 3 stacks depending on label size.");
Dialog.addNumber("   Diam1", 600,0,3,"Define size cut-off between stack 1 and 2");
Dialog.addNumber("   Diam2", 750,0,3,"Define size cut-off between stack 2 and 3");
Dialog.addMessage("  --Erode Large masks :\n        This step applies different erosion factors on each stack; largest labels may need higher erosion factor");
Dialog.addNumber("   small", 1, 0,2,"Factor applied on Labels < Diam1  (stack 1)");
Dialog.addNumber("   medium", 4,0,2, "Factor applied on Diam1 < Labels < Diam2  (stack 2)");
Dialog.addNumber("   large", 5,0,2, "Factor applied on Labels > Diam2  (stack 3)");
Dialog.addMessage("----HELP : see Help button for more details about parameters");
Dialog.addHelp(html);
Dialog.show();

//Paramaters values
Diam1 = Dialog.getNumber();
Diam2= Dialog.getNumber();
ReductionS= Dialog.getNumber();
ReductionM= Dialog.getNumber();
ReductionL= Dialog.getNumber();
Vol1= 4*(PI*(Diam1/2)*(Diam1/2)*(Diam1/2))/3;
Vol2= 4*(PI*(Diam2/2)*(Diam2/2)*(Diam2/2))/3;

//Starting macro
Keep_external_labels();

print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");
ID="03";
Save_infos(ID);
}
//////////////////////////////////
//////////////////////////////////
if (choice5=="YES") {
NameMacro="Combine";
Initialization();
setBatchMode(true);

//Main file directory
//showMessage("Combine Large&Small \n   FOLDERS ORGANIZATION: \n \n   --- ProjectName (=root folder): \n         --- Large_Masks \n         --- Results_StepByStep \n         --- Small_Masks \n \n   Click OK to select the Results_StepByStep folder");
Dialog.create("Before starting macro");     
Dialog.addMessage("----- FINAL STEP : COMBINE LABELS -----\n          -- Folder organization needed --", 16); 
Dialog.addMessage("\n\n\\.....\\ProjectName\\  (=Root folder) :\n \n       ....Pre-processed Image  (*name_image*.tif) \n       ....\\Step_by_step\\   (Subfolder)\n                      ....*name_image*_Small_external.tif\n                      ....*name_image*_Large_erode.tif");
Dialog.addMessage("Click OK to select the subfolder  \\Step_by_step\\", 14);
Dialog.addHelp(html_folder);
Dialog.show(); 

//dir folder
dir = getDirectory("SELECT \\Step_by_step\\ FOLDER");
RepResultat=dir;
//TEMP fodler
output= RepResultat;
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

//Parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<br><br><b>STEP 4 - Combine labels </b> : Combine Small and Large masks after filtration and cleaning process.<br>"
	 +"Use results from STEP 1 and STEP 3 and combine them together. No parameter needed. Adjust STEP 2.2 and STEP 3 if results are not satisfying. Label filtration is performed again at the end to clean small artifacts potentially created during combination. <b>Choose filtration parameters as in STEP 1.</b>" 
     +"</font>";
Dialog.addMessage("----- FINAL STEP : COMBINE -----   (and filter) :\n",14);
Dialog.addNumber("Diameter >", 50, 0, 2, "um  (Smaller labels will be deleted)");
Dialog.addNumber("Sphericity >", 0.5, 2, 3,"A value of 1.0 indicates a perfect sphere"); 	
Dialog.addHelp(html);
Dialog.show();

//Parameters value		
DiamS = Dialog.getNumber();
VolS= 4*(PI*(DiamS/2)*(DiamS/2)*(DiamS/2))/3;
SpherL = Dialog.getNumber();

print("---[ Filtration parameters ]---: " + "Diameter=" + DiamS + " µm;" +
" Sphericity=" + SpherL);			


//Starting macro

CombineLabels();

print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");
ID="04";
Save_infos(ID);
}
	
Ending_macro();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "Add Manually & Extract data Action Tool - icon:Add_Manually.png"{
	
function AddManually() { 
// function description
NameMacro="Add_manually";
Initialization();

////////////////////// DEFINING FOLDERS, FILES AND PARAMETERS /////////////////////////			
			
// Choose input data : Image data + Cp30-RESCp30_combined + RESCp60_labels
waitForUser("Please open : "+
"\n- Image data (pre-processed image)"+
"\n- Combined segmentation image (_cp_masks & _RES_cp_masks)"+
"\n- Segmentation image for manual label selection"+
"\n \n        Then press OK");
//Rename(short name)
Path1=getInfo("image.directory");
Name1=getTitle();
  if((endsWith(Name1, "cb_label_filtered.tif"))) {
	SampleName=replace(Name1, "cb_label_filtered.tif", "");
	print(SampleName);}
	close();

Path2=getInfo("image.directory");
Name2=getTitle();
  if((endsWith(Name2, "cb_label_filtered.tif"))) {
	SampleName=replace(Name2, "cb_label_filtered.tif", "");
	print(SampleName);}
	close();

Path3=getInfo("image.directory");
Name3=getTitle();
  if((endsWith(Name3, "cb_label_filtered.tif"))) {
	SampleName=replace(Name3, "cb_label_filtered.tif", "");
	print(SampleName);}
	close();

//Assign image and parameters
Label1 = newArray("Combined", "To_select", "Image");
Dialog.create("Combine Files");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Select manually labels to add</h2>"
+"Strategy is similar to automatic combination, but instead of selecting a full range of large label size, labels can be selected individually and manually.<br>"
+"Image “To_select” should be a Cellpose result (_cp_masks, _RES_cp_masks). Image “Combined” should be the result of automatic combination (STEP 1 to 4). Image “Image” should be the pre-processed image used for best resolution segmentation.<br>" 
     +"</font>";
Dialog.addMessage(Name1, 9);
Dialog.addChoice("Image type", Label1);
Dialog.addMessage(Name2, 9);
Dialog.addChoice("Image type", Label1);
Dialog.addMessage(Name3, 9);
Dialog.addChoice("Image type", Label1);		 	
Dialog.addMessage("------ Adjust size of selected labels \n       (Ex.: Set at 6 for follicles >600um diameter)");
Dialog.addSlider("Opening", 1, 30, 6);
Dialog.addMessage("------ Final filtration parameters:");
Dialog.addNumber("Diameter >", 50, 0, 1, "um   Clean small artifacts"); 
Dialog.addNumber("Sphericity >", 0.2, 2, 1,"Use a sphericity compatible with large labels (<0.4)"); 					 			
Dialog.addHelp(html);
Dialog.show();

//Parameters values
Newname1 = Dialog.getChoice();
Newname2 = Dialog.getChoice();
Newname3 = Dialog.getChoice();				
Open= Dialog.getNumber();
Diam = Dialog.getNumber();
VolS= 4*(PI*(Diam/2)*(Diam/2)*(Diam/2))/3;
SpherL = Dialog.getNumber();

// Output repertory
waitForUser("Please choose the ouput folder \n (a subfolder will be created)");
RepImage = getDirectory("Please choose the output folder");
			
// Create subfolder
	File.makeDirectory(RepImage + "/Labels-Added/"); 
	RepResultat = RepImage + "/Labels-Added/";
	output=RepResultat;
	
//TEMP folder
File.makeDirectory(output+"/TEMP/");
TEMP=output+"/TEMP/";

// Starting macro
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());	
print("----------[ IMAGE NAME: ]"+ SampleName);
print("---[ Large masks reduction Parameters ]---: " + "Opening: " + Open);


////////////////////// BEGINNING OF THE ANALYSES /////////////////////////
			
close("*");
open(Path1+Name1);
  rename(Newname1);
  saveAs("Tiff", TEMP + Newname1 + ".tif");		
open(Path2+Name2);
  rename(Newname2);
  saveAs("Tiff", TEMP + Newname2 + ".tif" );
open(Path3+Name3);
  rename(Newname3);
  saveAs("Tiff", TEMP + Newname3 + ".tif");

// Get info for resizing
selectWindow("Combined.tif");
SizeX= getWidth();
SizeY= getHeight();
SizeZ= nSlices;
getVoxelSize(width, height, depth, µm);
	
print("---[ Image size ]---: " + SizeX + " pixels" + "--" + SizeY +
      " pixels" + "--" + SizeZ + " pixels");
print("---[ Image Resolution ]---: " + "\t " + width + "\t " + "x " + height +
      "\t " + "x " + depth + "\t " + µm);
close("*");
	
		
// Resize, adjust resolution, filter & LabelBoundary
print("---[ RESIZE & BOUNDARIES ]---");													
open(TEMP + "To_select.tif");
	run("Size...", "width=SizeX height=SizeY depth=SizeZ interpolation=None");
	Sub_Mask_Boundary_3D();
saveAs("Tiff", TEMP + "To_select_BND.tif");
selectWindow("To_select_BND.tif");
	input=getTitle();
	numOpening=Open;	// **********
	opening3D_GPU();
	replace("open_Temp.tif", "open_Temp", "To_select_open");
	replace("To_select_open", ".tif", "");
	run("Size...", "width=SizeX height=SizeY depth=SizeZ interpolation=None");
	Stack.setXUnit("um");
	run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
saveAs("Tiff", TEMP + "To_select_open.tif");
close("*");
//Prepare for selection				
open(TEMP + "Combined.tif");
open(TEMP + "Image.tif");
run("16-bit");
saveAs("Tiff", TEMP + "Image.tif");
close();
open(TEMP + "Image.tif");
	run("Merge Channels...", "c1=Combined.tif c4=Image.tif create keep");
open(TEMP +"To_select_open.tif");
	setTool("multipoint");
	run("Synchronize Windows");
//				
  Dialog.create("Manual label selection");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Select manually labels to add</h2>"
     +"For label selection, \"Combined\" and \"Image\" will be merged into \"Composite\" to help detection of missing labels. Multi-point tool is used to select missing labels on the image \"To_select_open\". Synchronize Z-stacks with \"synchronize windows\" to facilitate stack navigation (select \"Composite\" and \"To_select_open\" stacks)." 
     +"</font>";
  Dialog.addMessage("At this step, please select on the \"To_select_open\" "+
  "image \nthe labels to add to the combined image");
  Dialog.addHelp(html);
  Dialog.show();
  
waitForUser("Please FIRST SELECT LABELS, \nthen press OK to continue \n \n Multiple click on the same label is allowed.");
  
		Dialog.create("Manual labels selection");
		Dialog.addMessage("Did you selected any labels?");
		Dialog.addCheckbox("Yes", false);
		Dialog.addMessage("(Click cancel to exit the macro)",10,"#ff0000");
		Dialog.show();
		Yes = Dialog.getCheckbox();
//
if (Yes){
//************** ADD LABELS FROM IMAGE  ****************************		
print("---[ LABELS SELECTED ]---");
	run("Interactive Morphological Reconstruction 3D", "type=[By Dilation] connectivity=6");
	saveAs("Tiff", RepResultat + SampleName+"Labels_selection.tif");
	close("\\Others");

print("---[ CLEAN OVER-SEGMENTED LABELS BEFORE COMBINATION ]---");
		
setBatchMode(true);

//To use defined functions : change names for corresponding inputs
dir=RepResultat;
rename("Large&Filtred_op.tif");
saveAs("Tiff", RepResultat + SampleName+"_Large&Filtred_op.tif");
open(TEMP+"Combined.tif");
saveAs("Tiff", RepResultat + SampleName+"_Small&Filtred.tif");

//Choose parameters
Dialog.create("Adjust parameters");
html = "<html>	See more information here : <a href=\"https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels\">Github</a>"
     +"<h2>Select manually labels to add</h2>"
     +"Strategy is similar to automatic combination, but instead of selecting a full range of large label size, labels can be selected individually and manually.<br>"
     +"<h2>Called functions</h2>"
     +"<b>Clean over-segmentation before combination</b> : Selected labels are used for detection of regions where over-segmentation needs to be deleted on Combined image. Incorrect labels within or touching those regions are then deleted. <br>"
     +"--Split large masks : Large labels are distributed in 3 different stacks depending on their size range. <b>Erosion factor may need to be higher when labels are larger, choose diameter limits accordingly</b>.<br>"
     +"--Erode Large masks : A label erosion is applied to each split stack. <b>Helps to avoid deletion of neighbours of large labels during combination by avoiding overlap</b>.<br>" 
     +"This is tightly linked to -Opening- process before selection of labels. Higher opening factor at will need smaller erosion factor."
     +"<br><br><b>Final filtration </b> : Size and shape filtering process. Use same parameters than STEP 1- filter small masks for Diameter, and same Sphericity than in STEP 2- filter large masks."
     +"</font></html>";
Dialog.addMessage("----- CLEAN OVER-SEGMENTATION BEFORE COMBINATION -----", 14)
Dialog.addMessage("  --Split Large masks : \n        This step splits image \"*_RES_cp_masks\" in 3 stacks depending on label size.");
Dialog.addNumber("   Diam1", 400,0,3,"Define size cut-off between stack 1 and 2");
Dialog.addNumber("   Diam2", 700,0,3,"Define size cut-off between stack 2 and 3");
Dialog.addMessage("  --Erode Large masks :\n        This step applies different erosion factors on each stack; largest labels may need higher erosion factor");
Dialog.addNumber("   small", 1, 0,2,"Factor applied on Labels < Diam1  (stack 1)");
Dialog.addNumber("   medium", 4,0,2, "Factor applied on Diam1 < Labels < Diam2  (stack 2)");
Dialog.addNumber("   large", 5,0,2, "Factor applied on Labels > Diam2  (stack 3)");	
Dialog.addMessage("------ Final filtration parameters:",14);
Dialog.addNumber("Diameter >", 50, 0, 1, "um  Clean small artifacts"); 
Dialog.addNumber("Sphericity >", 0.25, 3, 1, "Use a factor compatible with large labels (<0.4)"); 					  
Dialog.addMessage("HELP : see Help button for more details about parameters");
Dialog.addHelp(html);
Dialog.show();

// Paramaters values
Diam1 = Dialog.getNumber();
Diam2= Dialog.getNumber();
ReductionS= Dialog.getNumber();
ReductionM= Dialog.getNumber();
ReductionL= Dialog.getNumber();
Diam = Dialog.getNumber();
SpherL = Dialog.getNumber();
Vol1= 4*(PI*(Diam1/2)*(Diam1/2)*(Diam1/2))/3;
Vol2= 4*(PI*(Diam2/2)*(Diam2/2)*(Diam2/2))/3;
VolS= 4*(PI*(Diam/2)*(Diam/2)*(Diam/2))/3;

//ANALYSIS
// Find over-segmented labels and delete
Keep_external_labels();
print("---[ COMBINE SELECTED LABELS ]---");
CombineLabels();
			
open(RepResultat+SampleName+"_cb_label_filtered.tif");
FileResult_tif=getTitle();
FileResult=replace(FileResult_tif, ".tif", "");
replace(FileResult,"_cb_label_filtered", "Selected_cb_label_filtered");
saveAs("Tiff", RepResultat+FileResult);
print("\n......[ "+FileResult+" ]......saved ");
//DELETE
print(".....[ Deleting temporary files ].....");
Delete_temporary_files();
File.delete(output+"/TEMP/");

File.delete(RepResultat+SampleName+"_cb_label_filtered.tif");
File.delete(RepResultat+SampleName+"_Small_external.tif"
File.delete(RepResultat+SampleName+"_Large&Filtred_op.tif");
File.delete(RepResultat+SampleName+"_Small&Filtred.tif");


else {						
print("---[ NO LABELS SELECTED => ABORT ]---");
		Ending_macro(); }
		
End=getTime();
print("----------[ END OF MACRO. Total elapsed time]----------" + ElapsedTime(Start,End)); 
//ElapsedTime(Start,End);
ID="Manual_add";
Save_infos(ID);
Ending_macro();
}	

}				
		
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//macro "Delete manually & Extract data - icon:Delete_Manually.png" {

function DeleteManually() { 
// function description

NameMacro="Delete_manually_&_Extract";
Initialization();

waitForUser("Open the label image \"_cb_label_filtered\" that have to be modified + image data \nThen press OK");
	Name1=getTitle();
	Path1=getInfo("image.directory");
		if((endsWith(Name1, "cb_label_filtered.tif"))) {
		SampleName=replace(Name1, "cb_label_filtered.tif", "");
		print(SampleName);}
	close();
	
	Name2=getTitle();	
	Path2=getInfo("image.directory");
		if((endsWith(Name2, "cb_label_filtered.tif"))) {
		SampleName=replace(Name2, "cb_label_filtered.tif", "");
		print(SampleName);}
		close();
					
	Label1 = newArray("Combined", "Image");
	Label2 = newArray("2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30");
	Dialog.create("Manual deletion");
	html = "<html>"
     +"<h2>Select labels to delete</h2>" 
     +"</font>";
 	Dialog.addMessage(Name1, 9);
 	Dialog.addChoice("Image type", Label1);
	Dialog.addMessage(Name2, 9);
 	Dialog.addChoice("Image type", Label1);		 	
	Dialog.addMessage("Output filtration parameters:");				
	Dialog.addNumber("Diameter >", 50, 0, 1, "um"); // Delete labels with Equivalent Diameter < 40 um 
	Dialog.addMessage("		&");	
	Dialog.addNumber("Sphericity >", 0.2, 3, 1, "A value of 1.0 indicates a perfect ball (Default 0)");	
  	Dialog.addHelp(html);				 							 			
	Dialog.show();
	
	Newname1 = Dialog.getChoice();
	Newname2 = Dialog.getChoice();			
	Diam = Dialog.getNumber();
	Vol= 4*(PI*(Diam/2)*(Diam/2)*(Diam/2))/3;
	Spher = Dialog.getNumber();

// Main file directory
	RepImage = getDirectory("Please choose the ouput folder");

// Create subfolder
	File.makeDirectory(RepImage + "/Labels-Deleted/"); 
	RepResultat = RepImage + "/Labels-Deleted/";
	output=RepResultat;

// Create a results .xls file (with date, time and min. to avoid duplication).
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	Outputfile=File.open(RepResultat +"/Foll_Diameter_Delete_"+SampleName+"-"+dayOfMonth+"-"+(month+1)+"-"+year+"_"+hour+"-"+minute+".xls");
	print(Outputfile,"SampleName \tCalibration X,Y (um/pixel) \tCalibration Z (um/pixel) \tTotal Oocyte number \tOocytes Diameter (um)\t");
	
//Starting macro
Start= getTime();
print("----------[ STARTING MACRO: ]"+NameMacro+ "---------------------- "+getTimeString());
print("----------[ IMAGE ANALYZED: ]"+" "+SampleName);
print("----------[ CALIBRATION PARAMETERS ]---------- ");
print("---[ Filtration parameters ]---: " + "Diameter=" + Diam + " µm;" + " Sphericity=" + Spher);	

////////// BEGINNING OF THE MACRO //////////
//********** DELETE MASKS MANUALLY ***********************	
				open(Path1+Name1);
				rename(Newname1);
				saveAs("Tiff", RepResultat + Newname1 + ".tif");
			
				open(Path2+Name2);
				rename(Newname2);
				saveAs("Tiff", RepResultat + Newname2 + ".tif" );

			// Get info for resizing
				selectWindow("Image.tif");
				SizeX= getWidth();
				SizeY= getHeight();
				SizeZ= nSlices;
				getVoxelSize(width, height, depth, µm);
		print("---[ Image size ]---: " + SizeX + " pixels" + "--" + SizeY + " pixels" + "--" + SizeZ + " pixels");
	 	print("---[ Image Resolution ]---: " + "\t " + width + "\t " + "x " + height + "\t " + "x " + depth + "\t " + µm);
				close("*");
			
			open(RepResultat + "Combined.tif");
			open(RepResultat + "Image.tif");
				selectWindow("Image.tif");
				run("16-bit");
			saveAs("Tiff", RepResultat + "Image.tif");
				close();
			open(RepResultat + "Image.tif");
				run("Merge Channels...", "c1=Combined.tif c4=Image.tif create keep");
				selectWindow("Combined.tif");
				run("Label Edition");
				selectWindow("Label Edition");
				
		print("---[ MANUAL SELECTION OF LABELS ]---:");				
		waitForUser("Please click on masks and DELETE. \nThen, click DONE in the label editor. \n	\n         And press OK to continue:");	
		
				selectWindow("Combined-edited");
				close("\\Others");
				saveAs("Tiff", RepResultat + SampleName + "_Deleted_cb_label.tif");
				setTool("hand");
//				run("Close All");

//************** DATA EXTRACTION *****************************	
		print("---[ LABELS FILTRATION ]---:");		
		// Labels filtration
				Filtre_Sphericity=Spher;	// ********* 																					
				Filtre_Volume=Vol;			// *********				
				Filtration_3D();
				selectWindow("Stack_Filtre_Conserve");
				saveAs("Tiff", RepResultat + SampleName + "_Deleted_cb_label_filtered.tif");
				replace("_Deleted_cb_label_filtered.tif", ".tif", "");				
//				close("*");
				close("TableMesure");
		
		print("---[ DATA EXTRACTION ]---:");		
		// Data extraction (diameters)
				//run("Remove Border Labels", "left right top bottom front back");
				run("Analyze Regions 3D", "volume surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
				IJ.renameResults("TableMesure");
				NombreObjet=getValue("results.count");
				Mesure_Volume=newArray(NombreObjet);
				TableOocytesDiameter= newArray(NombreObjet);
				a=0;
				for (i = 0; i < NombreObjet; i++) {
		   		Mesure_Volume[i] = getResult("Volume", i);
				TableOocytesDiameter[a]=pow((6*Mesure_Volume[i]/PI),1/3);
				a++;
			 	}
				ChampMesure = "";
				ChampMesure = SampleName+"\t"+width+"\t"+height+"\t"+NombreObjet+"\t"+nResults+"\t"; 
				for(k=0; k<TableOocytesDiameter.length; k++){
				ChampMesure = ChampMesure+TableOocytesDiameter[k]+"\t";
				}
				print(Outputfile,ChampMesure+"\t");
				save(Outputfile);
				close("*");
				close("Results");
				close("TableMesure");
			
End=getTime();
print("----------[ END OF MACRO. Total elapsed time]----------" + ElapsedTime(Start,End)); 
ElapsedTime(Start,End);
ID="Manual_del";
Save_infos(ID);
Ending_macro();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
function ExtractData() {
	// Create a results .xls file (with date, time and min. to avoid duplication).
Initialization();

Dialog.create("Message");
Dialog.addMessage("Quantitative data extraction"+
"\n Number and 3D volume will be saved in an excel file"+
"\n \n WARNING : Images names should end with \"cb_label_filtered\"" );
Dialog.show();

dir= getDirectory("PLEASE CHOOSE RESULTS FOLDER");

File.makeDirectory(dir+"\\DATA\\");
output= dir + "\\DATA\\";
RepResultat=output;
filelist=getFileList(dir);

setBatchMode(true);
Start=getTime();

for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], "cb_label_filtered.tif") || (endsWith(filelist[i], "cb_label_filtered.TIF")))){
print("...[ File ]...: "+filelist[i]);
        	run("Close All");
       		run("Clear Results");
       		open(dir + File.separator + filelist[i]);
				Name1=getTitle();
				if((endsWith(Name1, "cb_label_filtered.tif"))) {
				SampleName=replace(Name1, "cb_label_filtered.tif", "");
				}
				SizeX= getWidth();
				SizeY= getHeight();
				SizeZ= nSlices;
				getVoxelSize(width, height, depth, µm);
print("---[ Image size ]---: " + SizeX + " pixels" + "--" + SizeY + " pixels" + "--" + SizeZ + " pixels");
print("---[ Image Resolution ]---: " + "\t " + width + "\t " + "x " + height + "\t " + "x " + depth + "\t " + µm);
	
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	Outputfile=File.open(RepResultat +"/Q_Data_"+SampleName+"_"+dayOfMonth+"-"+(month+1)+"-"+year+"_"+hour+"-"+minute+".xls");
	print(Outputfile,"SampleName \tCalibration X,Y (um/pixel) \tCalibration Z (um/pixel) \tTotal Oocyte number \tOocytes Diameter (um)\t");

Extract();
print("---[ Completed ]--- File saved in "+RepResultat);
close("*");
}
}
End=getTime();
print("----------[ END OF MACRO. Total elapsed time]----------" + ElapsedTime(Start,End)); 
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
macro "Draw Label Boundary & Resize Action Tool - icon:Label_BND.png"{

NameMacro="Draw_Label_Boundary_&_Resize";
Initialization();

Dialog.create("Macro Draw Label Boundary & Resize");
Dialog.addMessage("Macro information. How it works");
Dialog.show();

// Choose input directory containing data
	DirImages = getDirectory("File of analysis");	

// Output directory containing results
	File.makeDirectory(DirImages+"\\Label_Boundaries\\");
	RepResultat=DirImages+"\\Label_Boundaries\\";
	
////////////////////// BEGINNING OF THE ANALYSES /////////////////////////	
Start= getTime();
print("----------[ STARTING MACRO: ]"+NameMacro+ "---------------------- "+getTimeString());
setBatchMode(true);

	ListImage = 0;
	ListImage = getFileList(DirImages);
	print("Files detected = " + ListImage.length);
	nbImage = 0;

for (i=0; i < ListImage.length; i++){
			if((endsWith(ListImage[i], "_cp_masks.tif")) || (endsWith(ListImage[i], "_RES_cp_masks.tif"))) {
				if (filter(i, ListImage[i])) {
					print(ListImage.length);
		    		open(DirImages + File.separator + ListImage[i]);			
					print("...[ File ]...: "+ListImage[i]);					    		
					NameMasktif=getTitle();
					NameMask=replace(NameMasktif, "_cp_masks.tif", "");
					
					if(endsWith(NameMasktif, "_cp_masks.tif")) {
						NameImage=replace(NameMasktif, "_cp_masks.tif", "");;
						}
						
					if(endsWith(NameMasktif, "_RES_cp_masks.tif")) {
						NameImage=replace(NameMask, "_RES", "");
						}
						
		print(".....[ Geting size of ]..: "+ NameImage);									
				run("Bio-Formats Windowless Importer", "open=" + DirImages + NameImage + ".tif" +" view=Hyperstack stack_order=XYCZT");
				SizeX = getWidth();
				SizeY = getHeight();
				SizeZ = nSlices;
				getVoxelSize(ResX, ResY, ResZ, µm);
				close();
			
		print(".....[ Resizing: ]..: "+ NameMasktif);
		print("---[ Image Resolution ]---: " + ResX + " um" + " --" + ResY + " um" + " --" + ResZ + " um");
		print("---[ Image Size ]--- " +" X="+SizeX, " ; Y="+SizeY, " ; Z="+SizeZ  );
				run("Size...", "width=SizeX height=SizeY depth=SizeZ interpolation=None");
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=ResX pixel_height=ResY voxel_depth=ResZ");	
				
		print("......[ Compute boundaries overlay ].... ");
				Sub_Mask_Boundary_3D();
				saveAs("Tiff", RepResultat + NameMask + "_cp_BND.tif");
				close();
    }
        else {
            print("...Not an image ...");
        }
    }
    else {
        print("...Not a tiff file");    }
    }


End=getTime();
print("----------[ END OF MACRO. Total elapsed time]----------" + ElapsedTime(Start,End)); 
ElapsedTime(Start,End);
ID="_";
Save_infos(ID);
Ending_macro();
}

////////////////////// END OF THE MACRO /////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
///// LIST OF CALLED FUNCTIONS

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Initialization() { 
// Default settings & close windows
run("Options...", "iterations=1 black count=1"); // dark background	
run("Colors...", "foreground=white background=black selection=red"); // colour settings	
run("Appearance...", " "); // no inversion of LUTs
run("Close All");
close("TableMesure");
run("Clear Results");
run("Close All");
close("ROI Manager");
close("ROI Manager3D 4.0.36");
close("Log");
setTool("hand");
print("\\Clear");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Save_infos(ID) {
	// Save Log macro infos
selectWindow("Log");
path = RepResultat + ID+"_"+ NameMacro + "_infos";
saveAs("Text",path);
close("Log");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Ending_macro() { 
// Close windows & ending message
close("*");
close("Log");	
showMessage("  END OF MACRO" +"\n \n" +NameMacro+ "\n \n" + "All files have been processed");	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function CLAHEonStack() { 
//Run CLAHE on Stack for High Enhenced Contrast on stack
		print("......[ Running CLAHE ]... ");
			getDimensions( width, height, channels, slices, frames );
			isComposite = channels > 1;
			parameters =
			  "blocksize=" + blocksize +
			  " histogram=" + histogram_bins +
			  " maximum=" + maximum_slope +
			  " mask=" + mask;
			if ( fast )
			  parameters += " fast_(less_accurate)";
			if ( isComposite && process_as_composite ) {
			  parameters += " process_as_composite";
			  channels = 1;
			}
			   
			for ( f=1; f<=frames; f++ ) {
			  Stack.setFrame( f );
			  for ( s=1; s<=slices; s++ ) {
			    Stack.setSlice( s );
			    for ( c=1; c<=channels; c++ ) {
			      Stack.setChannel( c );
			      run( "Enhance Local Contrast (CLAHE)", parameters );
			     }
			  }
			}
        print("........[ Completed ] ");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Edge() {
//Edges substraction with Morphological gradient (MorphoLibJ)

if (choice=="Edge_border"){
print("......[ Running EDGE ]... Edge_border ");
	   		run("Duplicate...", "duplicate");
	   		run("Median 3D...", "x=2 y=2 z=2");
	   		run("Morphological Filters (3D)", "operation=[External Gradient] element=Ball x-radius=2 y-radius=2 z-radius=2");
	   		ext_gradient_tif= getTitle();
	   		imageCalculator("Subtract create stack",filename_tif, ext_gradient_tif);
	   	print(".........[ Completed ] ");
	   	}
	   	
if (choice=="Edge_border&cyto"){
print("......[ Running EDGE ]... Edge_borderé&cyto ");
		   	run("Duplicate...", "duplicate");
			run("Median 3D...", "x=1 y=1 z=1");
			Median=getTitle();
	
//Edges substraction/addition with Morphological gradient (MorphoLibJ)

print (".....Internal_Gradient");
		run("Morphological Filters (3D)", "operation=[Internal Gradient] element=Ball x-radius=4 y-radius=4 z-radius=4");
		Internal=getTitle();
		selectImage(Median);
print (".....Running_External_Gradient");
		run("Morphological Filters (3D)", "operation=[External Gradient] element=Ball x-radius=3 y-radius=3 z-radius=3");
		External=getTitle();
print (".....Image_calculator");
		imageCalculator("Add create stack",Median, Internal);
		Internal_added=getTitle();
		imageCalculator("Subtract create stack",Internal_added, External);
print(".........[ Completed ] ");

}}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function N2V() { 
//Run N2V
		print("......[ Running N2V ]... ");
	    	getPixelSize(unit, pw, ph, pd);			
			modelpath = ModelLocation + modelname + ".zip" ;
			run("bioimage.io prediction", "modelfile="+modelpath+" input="+InputImage+" axes=XYZ batchsize=10 numtiles=1 showprogressdialog=true convertoutputtoinputformat=true");
       		close("\\Others");
			Stack.setXUnit(unit);
			run("Properties...", "pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd+"");
			run("Window/Level...");
			run("Enhance Contrast", "saturated=0.35");
		print(".........[ Completed ]");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Downscaling() { 
//Run Downscaling
		print("......[ Running Downscaling ]... ");
			run("Resample", "factor="+X+" factor_0="+Y+" factor_1="+Z+"");
			getPixelSize(unit, pw, ph, pd);
		print(".........[ Pixel size after downscaling ]...:");
  			if (unit!="pixel" || pd!=1) {
      print("Pixel Size: "+pw+"x"+ph+"x"+pd + " " + unit);
      }
  }   	    
		print(".........[ Completed ] ");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function GetImageInfo() {
//Display information about the active image
  requires("1.32f");
  getPixelSize(unit, pw, ph, pd);
  if (unit!="pixel" || pd!=1) {
      print("Pixel Size: "+pw+"x"+ph+"x"+pd + " " + unit);
      }}   

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Label to Mask = separate labels generated with cellpose (that are touching each other)
function Sub_Mask_Boundary_3D(){ 
	masks=getTitle();
	run("Label Boundaries");
	bnd=getTitle();
	run("Binary Overlay", "reference="+masks + " binary="+bnd + " overlay=Black");
	run("8-bit");
	run("Options...", "iterations=1 count=1 black");
	setAutoThreshold("Default dark");
	run("Threshold...");
	setThreshold(1, 255);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	run("glasbey on dark");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Morphological 3D Opening on GPU
function opening3D_GPU(){
input=getTitle();
// Initialize the GPU and push image to GPU memory
	run("CLIJ2 Macro Extensions", "cl_device=HD");
	Ext.CLIJ2_clear();
// opening
	Ext.CLIJ2_push(input);
	Ext.CLIJ2_openingBox(input, temp, numOpening);
//show result
	Ext.CLIJ2_pull(temp);
saveAs("Tiff", TEMP+"open_Temp.tif");
	//Ext.CLIJ2_saveAsTIF(temp, TEMP+"open_Temp.tif");
	//Ext.CLIJ2_saveAsTIF(temp, RepResultat+"Temp.tif");
	Ext.CLIJ2_clear();
	close("*");
open(TEMP + "open_Temp.tif");
//open(RepResultat + "open_Temp.tif");
	close("\\Others");
	Ext.CLIJ2_clear();
	Ext.CLIJ2_push(input);
	Ext.CLIJ2_convertUInt8(input, output8bit);
	Ext.CLIJ2_release(input);
	Ext.CLIJ2_pull(output8bit);
	Ext.CLIJ2_clear();
	run("Options...", "iterations=1 count=1 black");
	run("Threshold...");
	setThreshold(1, 255);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	run("glasbey on dark");		
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Erode3D_GPU(numErosion){	
	for (i = 0; i < numErosion; i++) {
		input=getTitle();
		run("CLIJ2 Macro Extensions", "cl_device=HD");
		Ext.CLIJ2_clear();
		Ext.CLIJ2_push(input);
		image2="eroded"+i;
		Ext.CLIJ2_erodeSphereSliceBySlice(input, image2);
		Ext.CLIJ2_release(input);
		Ext.CLIJ_pull(image2);
		Ext.CLIJ2_clear();}
		image_eroded=getTitle();
		run("8-bit");
		run("Options...", "iterations=1 count=1 black");
		run("Threshold...");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Default background=Dark black");
		run("glasbey on dark");	
		}
	
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Morphological 3D dilatation on GPU - Dilate sphere in 3D

function dilate3D_GPU(){ 
	input=getTitle();
		run("CLIJ2 Macro Extensions", "cl_device=HD");
		Ext.CLIJ2_clear();
		Ext.CLIJ2_push(input);
		Ext.CLIJ_dilateSphere(input, "dilated0");	// iterative dilation
		for (i = 0; i < numDilations; i++) {
		Ext.CLIJ_dilateSphere("dilated"+i, "dilated"+(i+1)); }		
		Ext.CLIJ_pull("dilated"+ numDilations);
		Ext.CLIJ2_release(input);
		run("glasbey on dark");	
	saveAs("Tiff", TEMP+"dilate_Temp.tif");
		Ext.CLIJ2_clear();
		close("*");
	open(TEMP + "dilate_Temp.tif");	
		close("\\Others");
		run("8-bit");
		run("Options...", "iterations=1 count=1 black");
		run("Threshold...");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Default background=Dark black");
		run("glasbey on dark");		
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 3D labels filtration
function Filtration_3D(){
//		run("Remove Border Labels", "left right top bottom front back");		
		rename("Stack_Filtre_Conserve");
		run("Remap Labels");
		run("Duplicate...", "title=Stack_Filtre_Supprime duplicate");
		run("Analyze Regions 3D", "volume sphericity surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
		IJ.renameResults("TableMesure");
		NombreObjet=getValue("results.count");
		Mesure_Sphericity=newArray(NombreObjet);
		Mesure_Volume=newArray(NombreObjet);
		Label_A_Eliminer="";
		Label_A_Conserver="";
		NombreCelluleFinal=0;
		// Label filtration
		// Filtering labels and assigning to "keep" or "delete"
		for (i = 0; i < NombreObjet; i++) {
		   Mesure_Sphericity[i] = getResult("Sphericity", i);
		   Mesure_Volume[i] = getResult("Volume", i);
		   if ((Mesure_Sphericity[i]>Filtre_Sphericity) && (Mesure_Volume[i]>=Filtre_Volume)){
		   // Labels to keep
		   Label_A_Conserver=Label_A_Conserver+i+1+",";
		   }
		   else{
		   // Labels to delete	
		   	Label_A_Eliminer=Label_A_Eliminer+i+1+",";
		   	NombreCelluleFinal=NombreCelluleFinal+1;
		   }
		}
		// Delete labels
		if(Label_A_Eliminer!=""){
		selectWindow("Stack_Filtre_Conserve");
		run("Replace/Remove Label(s)", "label(s)="+Label_A_Eliminer+" final=0");
		}
		selectWindow("Stack_Filtre_Conserve");
		run("Labels To RGB", "colormap=[Golden angle] background=Black shuffle");
		rename("Stack_Filtre_Conserve_RGB");
		NombreCelluleSupprimer=NombreObjet-NombreCelluleFinal;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Split image by size classes
function Split_3D(){		
		rename("Stack_Filtre_small");
		run("Remap Labels");
		run("Duplicate...", "title=Stack_Filtre_large duplicate");
		run("Duplicate...", "title=Stack_Filtre_med duplicate");
		run("Analyze Regions 3D", "volume sphericity surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
		IJ.renameResults("TableMesure");
		NombreObjet=getValue("results.count");		
		Mesure_Sphericity=newArray(NombreObjet);
		Mesure_Volume=newArray(NombreObjet);
		Label_small="";
		Label_med="";
		Label_large="";
		NombreCelluleFinal=0;
		// Filtering labels and assigning to a class "small", "medium" or "large"
		for (i = 0; i < NombreObjet; i++) {
		   Mesure_Sphericity[i] = getResult("Sphericity", i);
		   Mesure_Volume[i] = getResult("Volume", i);
		   if ((Mesure_Sphericity[i]>Filtre_Sphericity) && (Mesure_Volume[i]<=Filtre_Volume)){
		   // List labels small (40um<labels<200um)
		   Label_small=Label_small+i+1+",";
		   }
		   else {
		   if ((Mesure_Sphericity[i]>Filtre_Sphericity_2) && (Mesure_Volume[i]>Filtre_Volume_2)){
		   // List labels large (>600um)
		   Label_large=Label_large+i+1+",";
		   }
		   else{
		   	//List labels medium (200um<labels<600um)
		   	Label_med=Label_med+i+1+",";
		   	NombreCelluleFinal=NombreCelluleFinal+1;
		   }}
		}
		SupSmall_and_med=Label_small+Label_med;
		SupSmall_and_large=Label_small+Label_large;
		Sup_med_and_large=Label_med+Label_large;	
		
		if(Label_small!=""){
		// Delete small&medium labels to create Large labels image
		selectWindow("Stack_Filtre_large");													/// Filtre LARGE
		run("Replace/Remove Label(s)", "label(s)="+SupSmall_and_med+" final=0");
		}	
		if(Label_med!=""){
		// Delete small&large labels to create medium labels image
		selectWindow("Stack_Filtre_med");													/// Filtre MEDIUM
		run("Replace/Remove Label(s)", "label(s)="+SupSmall_and_large+" final=0");
		}	
		if(Label_large!=""){
		// Delete medium&large labels to create small labels image
		selectWindow("Stack_Filtre_small");													/// Filtre SMALL
		run("Replace/Remove Label(s)", "label(s)="+Sup_med_and_large+" final=0");
		}
		selectWindow("Stack_Filtre_large");	
		saveAs("Tiff", TEMP+"Stack_Filtre_large.tif");
		//saveAs("Tiff", RepResultat+"Stack_Filtre_large.tif");
		selectWindow("Stack_Filtre_med");
		saveAs("Tiff", TEMP+"Stack_Filtre_med.tif");	
		//saveAs("Tiff", RepResultat+"Stack_Filtre_med.tif");
		selectWindow("Stack_Filtre_small");	
		saveAs("Tiff", TEMP+"Stack_Filtre_small.tif");
		//saveAs("Tiff", RepResultat+"Stack_Filtre_small.tif");	
		close("*");	
		NombreCelluleSupprimer=NombreObjet-NombreCelluleFinal;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Segmentation and assign labels (GPU assisted)
function Segmentation_Labelisation3D_GPU(){ 
		//run("16-bit");			
	input=getTitle();
// Initialize the GPU and push image to GPU memory
		run("CLIJ2 Macro Extensions", "cl_device=HD");
		Ext.CLIJ2_clear();
// seeded watershed
		Ext.CLIJ2_push(input);
		Ext.CLIJ2_push(input);
		temp =  "seeded_watershed";
		threshold = 1.0; //********** default 1.0
		Ext.CLIJx_seededWatershed(input, input, temp, threshold);
		Ext.CLIJ2_release(input);
		Ext.CLIJ2_pull(temp);
		run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
		run("glasbey on dark");
	saveAs("Tiff", TEMP+"Result_seg.tif");
	//saveAs("Tiff", RepResultat+"Result_seg.tif");	
		Ext.CLIJ2_clear();
		close("*");
	open(TEMP+"Result_seg.tif");
//		run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
//		run("glasbey on dark");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// RGB to Mask
function RGB_ToMask() { 
		run("Labels To RGB", "colormap=[Golden angle] background=Black shuffle");
		run("8-bit");
		run("Options...", "iterations=1 count=1 black");
		run("Threshold...");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Default background=Dark black");
		run("glasbey on dark");	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Delete pixels identified by Image Calculator
function ChangeValues_OnStack() { 
		setSlice(1);
		Z=nSlices;
		for (i = 1; i < Z; i++){
				run("Next Slice [>]");
				changeValues(0, 254, 0);
				}
		setSlice(1);
		}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Delete_temporary_files() {
	temp_list=getFileList(TEMP);
	for (i = 0; i < lengthOf(temp_list); i++) {
		File.delete(TEMP+temp_list[i]);
	}}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Filtering files
function filter(i, name) {
	//Filtering files : If false, file will not be processed
// is directory?
    if (endsWith(name,"/")) return false;
// is tiff?
    if (endsWith(name,".tif")==-1) return false;
    return true;
// ignore text files
    if (endsWith(name,".txt")) return false;
// does name contain "mask"
    if (indexOf(name,"mask")==-1) return false;
// open only first 10 images
// if (i>=10) return false;
    return true;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Time calculator
function TimeCalc(Start, End){ 
		Time = ((End-Start)/1000);
		print (Time*1000);
		hour = floor(Time/3600);
		min = floor ((Time/60)-(hour*60));
		sec = floor(Time-hour*3600-min*60);
		timeCalc = "[ "+hour+"h "+min+" min"+sec+"sec ]";
		return timeCalc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Time calculator
function ElapsedTime(Start,End){
	// Time for macro to complete (convert ms in hour+min+sec)
	macrotime=((End-Start)/1000);
	macrohour= floor(macrotime / 3600);
	macromin = floor((macrotime / 60) - (macrohour * 60));
	macrosec = floor(macrotime - macrohour * 3600- macromin * 60);
	elapsedtime= "[ "+macrohour+"h "+macromin+"min "+macrosec+"sec ]";
	return elapsedtime;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Get live Date & Time
function getTimeString(){
		MonthNames = newArray("January","February","March","April","May","Jun","July","August","September","October","November","December");
		DayNames = newArray("Sunday", "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		TimeString =" [Date: "+DayNames[dayOfWeek]+" ";
		if (dayOfMonth<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"]  [Time: ";
		if (hour<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+hour+":";
		if (minute<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+minute+":";
		if (second<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+second;
		return TimeString +"]";
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function About() {

	if(isOpen("Log")==1) { selectWindow("Log"); run("Close"); }
	
	  Dialog.create("About");
	  Dialog.addMessage("----- CLIP : Combine_Labels_and_Image_Pre_Processing -----", 16);
	  Dialog.addMessage("\nThe pipeline is designed for utilization of pre-trained deep-learning model Cellpose for segmentation of 3D images of ovaries "+
	  "\n(or round objects) without extensive annotation and training with specialized data."+
	  "\n-----Pre-processing steps (CLIP_Image Menu) are developed for 3D image stacks to improve visualization and the segmentation process,"+
	  "\nespecially for heterogeneous fluorescent staining."+
	  "\n-----Post-processing steps (CLIP_Labels Menu) are developed for correction of segmentation results and resolution of Cellpose limitation"+
	  "\nfor segmentation of a large variety of objects size (i.e 20um to 1200um in diameter for medaka ovaries)."+
	  "\n-----It works with either cytoplasmic fluorescent signal or contour staining of follicles. "+
	  "\n-----Automatic processing in available, and Step_by_step processing is recommended to begin analysis of new datasets for parameters testing, adjusting and validation", 14);
	  Dialog.addMessage("All Macros/Plugins in this CLIP Menu were written by Violette Thermes & Manon Lesage."+
	  "\n \nCopyright (C) V. Thermes & M. Lesage.\n \nRedistribution and use in source and binary forms of all plugins and macros, with or without modification, are permitted provided that the following conditions are met:"+
	  "\nRedistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer."+
	  "\nRedistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.", 11)

	  Dialog.addHelp("https://github.com/INRAE-LPGP/ImageAnalysis_CombineLabels");
	  Dialog.show();
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Filter_Large_masks() {
	
NameMacro="Filter_Large_masks";
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
			if(endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF"))) {
			run("Bio-Formats Windowless Importer", "open=" + dir + File.separator + filelist[i]+" view=Hyperstack stack_order=XYCZT");  //utiliser bio=format dans toutes les autres macros pour ouvrir les images (non masks)
       			NameImagetif = getTitle();
       			NameImage1 = replace(NameImagetif, ".tif", "");
				NameImage = replace(NameImagetif, "_CLAHE_EDGES_N2V.tif", "");
				SizeX = getWidth();							
				SizeY = getHeight();
				SizeZ = nSlices;
				getVoxelSize(width, height, depth, µm);
        		run("Close All");
       			run("Clear Results");
			open(DirLM + NameImage1 + "_RES_cp_masks.tif");
       			filename = getTitle();
				filename = replace(filename, ".tif", "");
				run("Size...", "width=SizeX height=SizeY depth=SizeZ interpolation=None");
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");						
				Filtre_Sphericity=SpherL;	//********* Min filter values
				Filtre_Volume=VolL;			//********* Min filter values
				Filtration_3D();
				selectWindow("Stack_Filtre_Conserve_RGB");			
				Sub_Mask_Boundary_3D();
				close("\\Others");
				rename(NameImage + "_Large&Filtred");
	   			FileResult_tif=getTitle();
	   			FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("Tiff", output + FileResult);
				close("*");			
				close("TableMesure");
	    print("\n......[ "+FileResult+" ]......saved ");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time : " + ElapsedTime(Start,End)+"]----------"); 
ElapsedTime(Start,End);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Filter_Small_masks() {
	
NameMacro="Filter_Small_masks";
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
			if(endsWith(filelist[i], ".tif") || (endsWith(filelist[i], ".TIF"))) {
			run("Bio-Formats Windowless Importer", "open=" + dir + File.separator + filelist[i]+" view=Hyperstack stack_order=XYCZT");  //utiliser bio=format dans toutes les autres macros pour ouvrir les images (non masks)
	      		NameImagetif = getTitle();
	      		NameImage1 = replace(NameImagetif, ".tif", "");
				NameImage = replace(NameImagetif, "_CLAHE_EDGES_N2V.tif", "");
				SizeX = getWidth();							
				SizeY = getHeight();
				SizeZ = nSlices;
				getVoxelSize(width, height, depth, µm);
        		run("Close All");
       			run("Clear Results");
			
// Resize, adjust resolution, filter & LabelBoundary
print("\n....[ Slight opening ]....");
			open(DirSM + NameImage1 + "_cp_masks.tif");
			    filename = getTitle();
				filename = replace(filename, ".tif", "");
				run("Size...", "width=SizeX height=SizeY depth=SizeZ interpolation=None");
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");	
				Sub_Mask_Boundary_3D();
			saveAs("Tiff", TEMP + "Small-BND.tif");
				numOpening=1;	// **********
				opening3D_GPU();
			saveAs("Tiff", TEMP + "Small-BND-open.tif");
				selectWindow("Small-BND-open.tif");
				close("\\Others");
				Segmentation_Labelisation3D_GPU();
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");				
				Filtre_Sphericity=SpherS;	//********* Min filter values
				Filtre_Volume=VolS;			//********* Min filter values
				Filtration_3D();
				selectWindow("Stack_Filtre_Conserve_RGB");
			saveAs("Tiff", TEMP + "Small&Filtred-RGB.tif");
				selectWindow("Stack_Filtre_Conserve");
				replace("Small&Filtred", ".tif", "");
			saveAs("Tiff", TEMP + "Small&Filtred.tif");
				close("TableMesure");
				close("*");
				
print("\n....[ Opening labels by size classes ]....");				
//Opening applied by size classes
			open(TEMP + "Small&Filtred.tif");
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
				Filtre_Sphericity=0;	// *********			
				Filtre_Volume=4188790.20478639; // ********** Labels < Filtre_Volume will be considered "small" // Default = 4188790.20478639 (Vol) = Equivalent Diameter = 200um	
				Filtre_Sphericity_2=0;	// *********
				Filtre_Volume_2=113097335.529233 ; // ********** Labels > Filtre_Volume2 will be considered "large" // Default = 113097335.529233 (Vol) = Equivalent Diameter = 600um
				
//Split image in 3 images : small, med, large, containing corresponding labels to apply opening
				Split_3D();
			open(TEMP+"Stack_Filtre_large.tif");
				RGB_ToMask();
				numOpening=6;	// **********
				opening3D_GPU();
			saveAs("Tiff", TEMP + "Stack_Filtre_large-Opening.tif");
				close("*");
				
			open(TEMP+"Stack_Filtre_med.tif");	
				RGB_ToMask();
				numOpening=3;	// **********
				opening3D_GPU();
			saveAs("Tiff", TEMP + "Stack_Filtre_med-Opening.tif");
				close("*");
				
			open(TEMP+"Stack_Filtre_small.tif");	
				RGB_ToMask();			
				numOpening=1;	// **********
				opening3D_GPU();
			saveAs("Tiff", TEMP + "Stack_Filtre_small-Opening.tif");		
				close("*");

print("\n....[ Image reconstruction of \"Small_Masks\" ]....");
				// Reconstruct full image after openings
			open(TEMP + "Stack_Filtre_large-Opening.tif");
			open(TEMP + "Stack_Filtre_small-Opening.tif");
				imageCalculator("Add create stack", "Stack_Filtre_large-Opening.tif", "Stack_Filtre_small-Opening.tif");	/// Add IMAGE Large + small
				ChangeValues_OnStack();
				replace("Small&Filtred1", ".tif", "");
				close("\\Others");					
			saveAs("Tiff", TEMP + "Small&Filtred1-open-OR1.tif");			
				close("*");

			open(TEMP + "Small&Filtred1-open-OR1.tif");
			open(TEMP + "Stack_Filtre_med-Opening.tif");
				imageCalculator("Add create stack", "Small&Filtred1-open-OR1.tif", "Stack_Filtre_med-Opening.tif");	/// Add IMAGE (large+small) + medium
				ChangeValues_OnStack();
				close("\\Others");
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");	
			rename(NameImage + "_Small&Filtred");
	   			FileResult_tif=getTitle();
	   			FileResult=replace(FileResult_tif, ".tif", "");
	  	 	saveAs("tiff", output + FileResult);
				close("TableMesure");
				close("*");					   		
	    print("\n......[ "+FileResult+" ]......saved ");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time : " + ElapsedTime(Start,End)+"]----------"); 
ElapsedTime(Start,End);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Opening_Large_masks() {
NameMacro="Opening_Large_masks";
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

filelist= getFileList(dir);
output=dir;
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], "Large&Filtred.tif") || 
    	(endsWith(filelist[i], "Large&Filtred.TIF")))){ //should end with Large&Filtered
    		
print("...[ File ]...: "+filelist[i]);
        	run("Close All");
       		run("Clear Results");
       	open(dir + File.separator + filelist[i]);
				filename = getTitle();
				filename = replace(filename, ".tif", "");
				SizeZ = nSlices;
				getVoxelSize(width, height, depth, µm);

print("\n......[ Opening ]......");
				numOpening=Opening;	// **********
				opening3D_GPU();		
				close("\\Others");	
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
				rename(filename + "_op");
	   			FileResult_tif=getTitle();
	   			FileResult=replace(FileResult_tif, ".tif", "");
	   		saveAs("tiff", dir + FileResult);	   		
print("\n......[ "+FileResult+" ]......saved ");
    }
}
End=getTime();
print("----------[ END OF MACRO. Elapsed time : " + ElapsedTime(Start,End)+"]----------"); 
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Keep_external_labels() {
NameMacro="Keep_external_labels";
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());

filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], "Large&Filtred_op.tif") || (endsWith(filelist[i], "Large&Filtred_op.TIF")))){
print("...[ File ]...: "+filelist[i]);
     		   	run("Close All");
       			run("Clear Results");
       		open(dir + File.separator + filelist[i]);
       			filename1_tif = getTitle();
				filename1 = replace(filename1_tif, "_Large&Filtred_op.tif", "");
				SizeZ = nSlices;
				getVoxelSize(width, height, depth, µm);
			
		// Stack preparation
				RGB_ToMask();
				Segmentation_Labelisation3D_GPU();
				Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");	
		
				//Erosion applied by size classes
				//Parameters for SPLIT : Diam_min(defined at Step Filtration), Diam1, Diam2
				Filtre_Sphericity=0;	// *********			
				Filtre_Volume=Vol1; // ********** Labels < Filtre_Volume will be considered "small" // Default = 4188790.20478639 (Vol) = Equivalent Diameter = 200um	
				Filtre_Sphericity_2=0;	// *********
				Filtre_Volume_2=Vol2; // ********** Labels > Filtre_Volume2 will be considered "large" // Default = 113097335.529233 (Vol) = Equivalent Diameter = 600um
				
print("\n....[ Label erosion on splitted image ]....");
				//Split image in 3 stacks (small, med, large) to apply different opening according to labels size
				Split_3D();
			open(TEMP+"Stack_Filtre_large.tif");
				Erode3D_GPU(ReductionL);
			saveAs("Tiff", TEMP + "Stack_Filtre_large-Erode.tif");
				close("*");		
			open(TEMP+"Stack_Filtre_med.tif");
				Erode3D_GPU(ReductionM);
			saveAs("Tiff", TEMP + "Stack_Filtre_med-Erode.tif");
				close("*");		
			open(TEMP+"Stack_Filtre_small.tif");
				Erode3D_GPU(ReductionS);
			saveAs("Tiff", TEMP + "Stack_Filtre_small-Erode.tif");
				close("*");	
				
print("\n....[ Label erosion full image reconstruction ]....");
				// Reconstruct full image after openings
			open(TEMP + "Stack_Filtre_large-Erode.tif");
			open(TEMP + "Stack_Filtre_small-Erode.tif");
				imageCalculator("Add create stack", "Stack_Filtre_large-Erode.tif", "Stack_Filtre_small-Erode.tif");	/// Add IMAGE Large + small
				ChangeValues_OnStack();
				replace("Large_eroded_OR1", ".tif", "");
				close("\\Others");					
			saveAs("Tiff", TEMP + "Large_erode_OR1.tif");			
				close("*");
				
			open(TEMP + "Large_erode_OR1.tif");
			open(TEMP + "Stack_Filtre_med-Erode.tif");
				imageCalculator("Add create stack", "Large_erode_OR1.tif", "Stack_Filtre_med-Erode.tif");	/// Add IMAGE (large+small) + medium
				ChangeValues_OnStack();
				close("\\Others");
				close("TableMesure");
			saveAs("Tiff", dir + filename1 +"_Large_erode.tif");
				rename("Large_erode.tif");
				
print("\n....[ Cleaning over-segmentation of large labels ]....");
		// Create small external
			open(dir + filename1 + "_Small&Filtred.tif");
				RGB_ToMask();
				rename("Small&Filtred8bit");
				run("Morphological Reconstruction 3D", "marker=Large_erode.tif mask=Small&Filtred8bit type=[By Dilation] connectivity=6");
				rename("Small_internal.tif");
				replace("Small_internal", ".tif", "");				
				imageCalculator("Subtract create stack","Small&Filtred8bit","Small_internal.tif");
				ChangeValues_OnStack();
	   		rename(filename1 + "_Small_external");
	   			FileResult_tif=getTitle();
	   			FileResult=replace(FileResult_tif, ".tif", "");
	   			Stack.setXUnit("um");
				run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
	   		saveAs("tiff", dir + FileResult);
	    print("\n......[ "+FileResult+" ]......saved ");
    	}
	}
End=getTime();
print("----------[ END OF MACRO. Elapsed time : " + ElapsedTime(Start,End)+"]----------"); 
ElapsedTime(Start,End);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function CombineLabels() {
	
NameMacro="Combine";
Start= getTime();
print("\n----------[ STARTING MACRO: ]----------"+NameMacro+ "----------");
print(getTimeString());
//
filelist= getFileList(dir);
for (i=0; i < lengthOf(filelist); i++){
    if((endsWith(filelist[i], "Small_external.tif") || (endsWith(filelist[i], "Small_external.TIF")))){
print("...[ File ]...: "+filelist[i]);
     	run("Close All");
       	run("Clear Results");
       	open(dir + File.separator + filelist[i]);
       		filename1_tif = getTitle();
			filename1 = replace(filename1_tif, "_Small_external.tif", "");
			SizeZ = nSlices;
			getVoxelSize(width, height, depth, µm);
		saveAs("Tiff", dir + filename1_tif);
				
print("\n....[ Trimming ]....");				
			RGB_ToMask();
			numDilations=3;	// **********
			dilate3D_GPU();	
		saveAs("Tiff", TEMP + "Dilated.tif");				
		open(dir + filename1 +"_Large_erode.tif");
		rename("Large_erode.tif");
			imageCalculator("Subtract create stack", "Large_erode.tif","Dilated.tif");
			ChangeValues_OnStack();
		saveAs("Tiff", TEMP + "Trim.tif");		
			close("\\Others");
			
print("\n....[ Combining labels ]....");
		open(dir + filename1_tif); //=*name*_Small_external.tif
			RGB_ToMask();
			rename("Small_external8bit");
			imageCalculator("Add create stack", "Trim.tif","Small_external8bit");
			ChangeValues_OnStack();
			rename("Result");
			replace("Result", ".tif", "");
			close("\\Others");
			
print("\n....[ Segmentation ]....");
			Segmentation_Labelisation3D_GPU();
			rename("cb_label.tif");
			close("\\Others");	
						
print("\n....[ Filtering ]....");		
	   		Stack.setXUnit("um");
			run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
			Filtre_Sphericity=SpherL;	// ********* 
			Filtre_Volume=VolS;	// Delete labels with Equivalent Diameter < 40 um ************************
			Filtration_3D();
			selectWindow("Stack_Filtre_Conserve");			
	   		Stack.setXUnit("um");
			run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
		rename(filename1 + "_cb_label_filtered.tif");
			FileResult_tif=getTitle();
			FileResult=replace(FileResult_tif, ".tif", "");
	   		Stack.setXUnit("um");
			run("Properties...", "channels=1 slices=SizeZ frames=1 pixel_width=width pixel_height=height voxel_depth=depth");
		saveAs("tiff", dir + FileResult);
			close("*");
			close("TableMesure");
print("\n......[ "+FileResult+" ]......saved ");
			}
	}								
			
End=getTime();
print("----------[ END OF MACRO. Elapsed time : " + ElapsedTime(Start,End)+"]----------");
	}
	
/////////////////////////////////////////////////////////
function Extract() {
	
print("---[ DATA EXTRACTION ]---:");		
		// Data extraction (diameters)
				//run("Remove Border Labels", "left right top bottom front back");
				run("Analyze Regions 3D", "volume surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
				IJ.renameResults("TableMesure");
				NombreObjet=getValue("results.count");
				Mesure_Volume=newArray(NombreObjet);
				TableOocytesDiameter= newArray(NombreObjet);
				a=0;
				for (i = 0; i < NombreObjet; i++) {
		   		Mesure_Volume[i] = getResult("Volume", i);
				TableOocytesDiameter[a]=pow((6*Mesure_Volume[i]/PI),1/3);
				a++;
			 	}
				ChampMesure = "";
				ChampMesure = SampleName+"\t"+width+"\t"+depth+"\t"+NombreObjet+"\t"+nResults+"\t"; 
				for(k=0; k<TableOocytesDiameter.length; k++){
				ChampMesure = ChampMesure+TableOocytesDiameter[k]+"\t";
				}
				print(Outputfile,ChampMesure+"\t");
				save(Outputfile);
				close("*");
				close("Results");
				close("TableMesure");
	}
	

/////////////////////////////////////