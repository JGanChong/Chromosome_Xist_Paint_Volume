/*  Segment and calculate the volumes of paints in 3D from Channels 1 and 2. Output result table and projected image with ROI to verify segmentation.
 *  
 * Macro Instructions:
 * Set desired settings and run.
 *  
 * Macro tested with ImageJ 1.53g, Java 1.8.0_172 (64bit) Windows 10
 * Macro by Johnny Gan Chong email:behappyftw@g.ucla.edu 
 * January 2021
 */


//************ Create user interface to get settings ****************//
// Change second value to change default. Create a backup first if you are not very sure
Dialog.create("Settings");
Dialog.addDirectory("Input", "/");
Dialog.addString("Files ending in", ".tif");
Dialog.addMessage("\n");
Dialog.addMessage("Chanell 1 settings");
x = newArray("3D Minimum FLT","3D Mean FLT","Unsharp Mask","Subtract Background");
y = newArray(true,true,true,true);
Dialog.setInsets(5, 20, 5);
Dialog.addCheckboxGroup(2,2,x,y);

Dialog.addNumber("Threshold", 5.2);
Dialog.addNumber("Min size (pixels)", 5000);
Dialog.addMessage("\n");
Dialog.addNumber("3D Minimum radius", 1);
Dialog.addNumber("3D Mean radius", 5);
Dialog.addNumber("Unsharp Mask Radius", 100);
Dialog.addNumber("Unsharp Mask Amount", 0.55);
Dialog.addNumber("Subtract Background", 25);


Dialog.addMessage("\n");
Dialog.addMessage("Chanell 2 settings");
x = newArray("3D Minimum FLT","3D Mean FLT","Unsharp Mask","Subtract Background");
y = newArray(false,true,false,false);
Dialog.setInsets(5, 20, 5);
Dialog.addCheckboxGroup(2,2,x,y);

Dialog.addNumber("Threshold", 8);
Dialog.addNumber("Min size (pixels)", 750);
Dialog.addMessage("\n");
Dialog.addNumber("3D Minimum radius", 0);
Dialog.addNumber("3D Mean radius", 2);
Dialog.addNumber("Unsharp Mask Radius", 0);
Dialog.addNumber("Unsharp Mask Amount", 0);
Dialog.addNumber("Subtract Background", 0);

Dialog.show();


input = Dialog.getString();
endingwith = Dialog.getString();


c1_doMin = Dialog.getCheckbox();
c1_doMean = Dialog.getCheckbox();
c1_doUnsharp = Dialog.getCheckbox();
c1_doSubstract = Dialog.getCheckbox();

c1_thr = Dialog.getNumber();
c1_minSize = Dialog.getNumber();
c1_getMin = Dialog.getNumber();
c1_geMean = Dialog.getNumber();
c1_getUnsharp1 = Dialog.getNumber();
c1_getUnsharp2 = Dialog.getNumber();
c1_getSubstract = Dialog.getNumber();


c2_doMin = Dialog.getCheckbox();
c2_doMean = Dialog.getCheckbox();
c2_doUnsharp = Dialog.getCheckbox();
c2_doSubstract = Dialog.getCheckbox();

c2_thr = Dialog.getNumber();
c2_minSize = Dialog.getNumber();
c2_getMin = Dialog.getNumber();
c2_geMean = Dialog.getNumber();
c2_getUnsharp1 = Dialog.getNumber();
c2_getUnsharp2 = Dialog.getNumber();
c2_getSubstract = Dialog.getNumber();




//************ Prep imagej ****************//
//closes all opened images/result table and sets options
close("*");
setBatchMode(true);
run("3D OC Options", "volume nb_of_obj._voxels dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
setOption("BlackBackground", true);
if (isOpen("Results")==true) {
	close("Results");
}

//gets input directory and creates output directory
list = getFileList(input);
list = Array.sort(list);
File.makeDirectory(File.getParent(input)+File.separator+"Output" );
output = File.getParent(input)+File.separator+"Output";



for (i = 0; i < list.length; i++) {
	if(endsWith(list[i], endingwith)){
			
		//************ Stars processing each image ****************//
		//Open files
		open(input + list[i]);
		
		//Get Image properties
		title = getTitle();
		noExt = File.nameWithoutExtension;
		getVoxelSize(width, height, depth, unit);
		voxel_volume = width*height*depth;
		Stack.getDimensions(width, height, channels, slices, frames);
		
		//Get name of images after splitting channels
		C1 = "C1-"+title; 
		C2 = "C2-"+title;
		C3 = "C3-"+title;
		
		
		//Split channel
		run("Split Channels");
		
		//************ Process Channel 1 ****************//
		selectWindow("C1-" + title);
		
		//Filters
		if (c1_doMin == true) {
			run("Minimum 3D...", "x="+c1_getMin +" y="+c1_getMin +" z="+c1_getMin);
		}
		
		if (c1_doMean == true) {
			run("Mean 3D...", "x="+c1_geMean +" y="+c1_geMean +" z="+c1_geMean);
		}
		
		if (c1_doUnsharp == true) {
			run("Unsharp Mask...", "radius="+c1_getUnsharp1 +" mask="+c1_getUnsharp2 +" stack");
		}
		
		if (c1_doSubstract == true) {
			run("Subtract Background...", "rolling="+c1_getSubstract +" disable stack");
		}
		

		 //Segment
		thr = getTHR(c1_thr);
		selectWindow("C1-" + title);
		run("3D Objects Counter", "threshold="+thr+" slice=1 min.="+c1_minSize+" max.=9999999 objects");

		//get volume
		volume=0;
		for (sli = 1; sli <= slices; sli++) {
		selectImage("Objects map of " + "C1-" + title);
		setSlice(sli);
		changeValues(1, 255, 255);
		volume=volume+((getValue("IntDen limit raw")/255)*(voxel_volume));
		}

		//set results
		row = nResults;
		setResult("Cell", row, noExt);
		setResult("Channel", row, "Channel 1");
		setResult("Volume", row, volume);
		project("C1-" + title,255,0,0);

		//saves image for user to check later
		saveAs("png", output+File.separator+"C1PROJ"+noExt+".png");

		//closes all channel 1 files
		close();

		
		//************ Process Channel 2 ****************//	
		selectWindow("C2-" + title);
		//Filters
		if (c2_doMin == true) {
			run("Minimum 3D...", "x="+c2_getMin +" y="+c2_getMin +" z="+c2_getMin);
		}
		
		if (c2_doMean == true) {
			run("Mean 3D...", "x="+c2_geMean +" y="+c2_geMean +" z="+c2_geMean);
		}
		
		if (c2_doUnsharp == true) {
			run("Unsharp Mask...", "radius="+c2_getUnsharp1 +" mask="+c2_getUnsharp2 +" stack");
		}
		
		if (c2_doSubstract == true) {
			run("Subtract Background...", "rolling="+c2_getSubstract +" disable stack");
		}
		//Segment
		thr = getTHR(c2_thr);
		selectWindow("C2-" + title);
		run("3D Objects Counter", "threshold="+thr+" slice=1 min.="+c2_minSize+" max.=9999999 objects");
		
		//Get volume
		volume=0;
		for (sli = 1; sli <= slices; sli++) {
		selectImage("Objects map of " + "C2-" + title);
		setSlice(sli);
		changeValues(1, 255, 255);
		volume=volume+((getValue("IntDen limit raw")/255)*(voxel_volume));
		}

		//set results
		row = nResults;
		setResult("Cell", row, noExt);
		setResult("Channel", row, "Channel 2");
		setResult("Volume", row, volume);
		project("C2-" + title,0,255,0);
		//save image
		saveAs("png", output+File.separator+"C2PROJ"+noExt+".png");
		
		//updates result table and closes all images
		updateResults();
		close("*");
		
	}
}
selectWindow("Results");
saveAs("Results", output+File.separator+"Results.csv");
setBatchMode("show");
setBatchMode(false);
	
//function to get threshold. 
//Gets the max value and divides over the user threshold
function getTHR(multiplier) {
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	thr = max/multiplier;
	return thr;
}

//function to create "verification" image for user to check afterwards
function project(activeimage,r,g,b) {
	
	selectImage("Objects map of " + activeimage);
	run("Z Project...", "projection=[Max Intensity]");
	changeValues(1, 255, 255);
	run("Select All");
	run("Create Selection");
	
	selectImage(activeimage);
	run("Z Project...", "projection=[Max Intensity]");
	run("Grays");
	run("RGB Color");
	setForegroundColor(r, g, b);
	run("Restore Selection");
	run("Line Width...", "line=1");
	run("Draw", "slice");
	
}
