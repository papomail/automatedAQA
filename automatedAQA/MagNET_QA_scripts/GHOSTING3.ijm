
macro "GHOSTING" {

TestName="GHOSTING";

close("*");
////Use if you want to call the macro with arguments
//arguments=getArgument()
//arguments="hello, world";
//arg_array=split(arguments,",,");
//myfilename=arg_array[0];
//Results_dir=arg_array[0];


//Retrieve filenames and Results_dir path 
Results_dir = call("ij.Prefs.get", "myMacros.savedir", "defaultValue"); 
GHOSTING_1 = call("ij.Prefs.get", "myMacros.GHOSTING_1", "defaultValue"); 
GHOSTING_2 = call("ij.Prefs.get", "myMacros.GHOSTING_2", "defaultValue"); 


//Ghoting_ROIs=

// run GHOSTING TEST:
GHOSTING_TEST(GHOSTING_1,GHOSTING_2,Results_dir);





//////////////////////////
/// Function definition:   GHOSTING_TEST
// Runs the main GHOSTING_TEST and produces the results in csv file and the screenshots to check ROI selection. 
function GHOSTING_TEST(filename,filename2,results_dir) {



outdir=results_dir+File.separator+"GHOSTING";
screenshot_dir=outdir+File.separator+"ScreenshotCheck";
//Create GHOSTING folder
if ( File.isDirectory(outdir)==0 ){
print("Creating folder "+ outdir);
File.makeDirectory(outdir);
}
//Create screenshot_dir folder
if ( File.isDirectory(screenshot_dir)==0 ){
print("Creating folder "+ screenshot_dir);
File.makeDirectory(screenshot_dir);
}



//open both images
open(filename);
myimage=getTitle();
open(filename2);
myimage2=getTitle();

// Find centre from the NSA=2 image
selectWindow(myimage2);  
bottle_pos2=find_bottle_2022();
print("Phantom centre in the second image is at x,y ="); 
Array.print(bottle_pos2); //show central point (x,y) of the phantom


image_width = getWidth;  //PATCH for when phantom is on the lower right corner
if (bottle_pos2[0] > image_width/2){ 
	selectWindow(myimage2);    
	run("Rotate 90 Degrees Right");  //ROTATE90 when phantom is on the lower right corner
	selectWindow(myimage);    
	run("Rotate 90 Degrees Right");  //ROTATE90 when phantom is on the lower right corner
	};


	
// Find centre from the NSA=1 image AFTER POSSIBLE ROTATION
selectWindow(myimage);  
bottle_pos=find_bottle_2022();
print("Phantom centre in the first image is at x,y ="); 
Array.print(bottle_pos); //show central point (x,y) of the phantom

// Find centre from the NSA=2 image AFTER POSSIBLE ROTATION
selectWindow(myimage2);  
bottle_pos2=find_bottle_2022();
print("Phantom centre in the second image is at x,y ="); 
Array.print(bottle_pos2); //show central point (x,y) of the phantom





// draw ROIs and do the maths for Ghosting measure:  Ghosting = 100*abs(Maximum Ghost–Noise)/Signal
// Ghosting_NSA1=ROIs_Draw_Cal(myimage,bottle_pos); 
// Ghosting_NSA2=ROIs_Draw_Cal(myimage2,bottle_pos2); 
Ghosting_NSA1=ROIs_Draw_Cal(myimage,bottle_pos);   //PATCH for when rois are not the same (uses the same bottle_pos for each)
Ghosting_NSA2=ROIs_Draw_Cal(myimage2,bottle_pos);   //PATCH for when rois are not the same (uses the same bottle_pos for each)


//take screenshots
TakeScreenshot(myimage,screenshot_dir,TestName);
TakeScreenshot(myimage2,screenshot_dir,TestName);


//saves the ghosting measure to a results table
run("Clear Results");
for (i = 0; i < Ghosting_NSA1.length; i++) {
setResult("Ghosting_NSA1", i, Ghosting_NSA1[i]);
setResult("Ghosting_NSA2", i, Ghosting_NSA2[i]);
updateResults();
}

//saves the results to a .csv file 
saveAs("Results", outdir+File.separator+myimage+"_"+TestName+".csv");


Array.print(Ghosting_NSA1);
Array.print(Ghosting_NSA2);



}








//////////////////////////
/// Function definition:  TakeScreenshot
function TakeScreenshot(myimage,screenshot_dir,TestName) {
selectWindow(myimage);
setLocation(1,1,1028,1028);
wait(100);
myscreenshot=screenshot_dir+File.separator+myimage+"_"+TestName+".png";
exec("screencapture", myscreenshot);
// setLocation(1,1,300,300);
}




/// Function definition:  CreateROIs
function ROIs_Draw_Cal(myimage,bottle_pos) {
//Creates ROIs needed for GHOSTING_TEST and calculates the Ghosting measure from them. Ghosting = 100*abs(Maximum Ghost–Noise)/Signal

selectWindow(myimage);  

//bottle position and dimension
xx=bottle_pos[0];
yy=bottle_pos[1];
ww=bottle_pos[2];
hh=bottle_pos[3];

//create rois for noise measure
nxx=xx+105;
nyy=yy-105;

//off_pos=newArray(140+40,33+65);
roiManager("reset");
makeRectangle(nxx-40, nyy-65, 20, 20);
roiManager("add");
makeRectangle(nxx+40, nyy-65, 20, 20);
roiManager("add");
makeRectangle(nxx-40, nyy+45, 20, 20);
roiManager("add");
makeRectangle(nxx+40, nyy+45, 20, 20);
roiManager("add");
roiManager("select", newArray(0, 1, 2, 3));
roiManager("combine");
roiManager("add");
roiManager("select", newArray(0, 1, 2, 3));
roiManager("delete");
roiManager("select", 0);
roiManager("rename", "Noise");

//create roi for signal measure
roi_size=16;
makeRectangle(xx-roi_size/2, yy-roi_size/2, roi_size, roi_size);
roiManager("add");
roiManager("select", 1);
roiManager("rename", "Signal");


// Calculate Noise and Signal values
roiManager("select", newArray(0,1));
//run("Set Measurements...", "  mean redirect=None decimal=2");
run("Set Measurements...", "  median redirect=None decimal=2");

run("Clear Results");


Stack.getDimensions(width, height, channels, slices, frames);

Signal=newArray(slices);
Noise=newArray(slices);


roiManager("multi measure")
for (i = 0; i < slices; i++) {
//Signal[i]=getResult("Mean(Signal)", i);
//Noise[i]=getResult("Mean(Noise)", i);
Signal[i]=getResult("Median(Signal)", i);
Noise[i]=getResult("Median(Noise)", i);

}

//print("Mean Signal values for the 4 echoes are:");
print("Median Signal values for the 4 echoes are:");

Array.print(Signal);
//print("Mean Noise values for the 4 echoes are:");
print("Median Noise values for the 4 echoes are:");

Array.print(Noise);


//create roi of max ghosting 
rc=newArray(-2,-1,1,2,3,4,5,6,7,8);

for (i = 0; i < lengthOf(rc); i++) {
	makeRectangle(xx+rc[i]/abs(rc[i])*ww/2-roi_size/2+20*rc[i],yy-roi_size/2, roi_size, roi_size);
roiManager("add");
roiname="G"+i;
roiManager("select", i+2);
roiManager("rename", roiname);
}



// create all possible ghosting rois
for (i = 0; i < lengthOf(rc); i++) {
	makeRectangle(xx-roi_size/2,yy-rc[i]/abs(rc[i])*hh/2-roi_size/2-20*rc[i], roi_size, roi_size);
roiManager("add");
roiname="G"+i+lengthOf(rc)+1;
roiManager("select", i+2+lengthOf(rc));
roiManager("rename", roiname);
}

L=2*lengthOf(rc);
kk=Array.getSequence(L);
for (i = 0; i < L; i++) {
kk[i]=kk[i]+2;
}

roiManager("select", kk);
roiManager("show all");

//select the roi with max ghosting (from the first echo)
//run("Set Measurements...", "  mean redirect=None decimal=2");
run("Set Measurements...", "  median redirect=None decimal=2");

run("Clear Results");
roiManager("measure");

ghosts=newArray(L);
for (i = 0; i < L; i++) {
	//ghosts[i]=getResult("Mean", i);
	ghosts[i]=getResult("Median", i);
}

print("Ghosts:");
Array.print(ghosts);
sortGhosts=Array.rankPositions(ghosts);
print("Sorted ghosts rank:");
Array.print(sortGhosts);

roiManager("deselect");
roiManager("deselect");

//roiManager("select", 2+sortGhosts[sortGhosts.length-1]); //Select the ROI with max ghosting. 
roiManager("select", 2+sortGhosts[sortGhosts.length-3]); //Select the ROI with max ghosting. (first two rois correspond to Noise and Signal, 1st and 2nd noise phantoms are to close; 3rd is chose from the noise. 5th in the list)

roiManager("add");

roiManager("select", roiManager("count")-1);
roiManager("rename", "MaxGhost");

//Delete the ghost ROIs that aren't the maximum
roiManager("select", kk); 
roiManager("delete");

//get maxghost values
MaxGhost=newArray(slices);
roiManager("select", roiManager("count")-1);
roiManager("multi measure");
for (i = 0; i < slices; i++) {
//MaxGhost[i]=getResult("Mean(MaxGhost)", i);
MaxGhost[i]=getResult("Median(MaxGhost)", i);

}

roiManager("show all with labels")")

//Calculate the ghosting measure
Ghosting_measure=newArray(slices);
for (i = 0; i < slices; i++) {
Ghosting_measure[i]=100*abs(MaxGhost[i]-Noise[i])/Signal[i];

}
return Ghosting_measure;



}




/////////////////////////////////////
// //Function definition

function find_bottle_2022(){
run("Set Measurements...", "center redirect=None decimal=2");
run("Duplicate...", "title=dup");
selectWindow("dup");
run("Auto Threshold", "method=Default white");
run("Invert");
run("Analyze Particles...", "size=100-1000 circularity=0.80-1.00 display exclude clear summarize add");
xpos=getResult("XM") + 2; //pull the X pos to the right to compensate for the non-spherical centre
ypos=getResult("YM") + 5; //pushes the Y pos slightly down to compensate for the non-spherical centre
position=newArray(xpos,ypos,40,40);
close();
//run("Set Measurements...", "  mean redirect=None decimal=2");
run("Set Measurements...", "  median redirect=None decimal=2");

return position;
	};//end of function


}