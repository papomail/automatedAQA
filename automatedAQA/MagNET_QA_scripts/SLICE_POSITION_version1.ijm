

close("*");
roiManager("reset");


macro "SLICE_POSITION" {

////Use if you want to call the macro with arguments
//arguments=getArgument()
//arguments="hello, world";
//arg_array=split(arguments,",,");
//myfilename=arg_array[0];
//Results_dir=arg_array[0];


//Retrieve filenames and Results_dir path 
Results_dir = call("ij.Prefs.get", "myMacros.savedir", "defaultValue"); 
SLICE_POS = call("ij.Prefs.get", "myMacros.SLICE_POS", "defaultValue"); 



// run SIGNAL UNIFORMITY TEST for 3 slice orientations:
SLICE_POSITION_TEST(SLICE_POS,Results_dir);







//////////////////////////
/// Function definition:   GEOMETRIC_LINEARITY_TEST
function SLICE_POSITION_TEST(filename,results_dir) {



outdir=results_dir+File.separator+"SLICE_POSITION";
screenshot_dir=outdir+File.separator+"ScreenshotCheck";
//Create uniformity folder
if ( File.isDirectory(outdir)==0 ){
print("Creating folder "+ outdir);
File.makeDirectory(outdir);
}
//Create screenshot_dir folder
if ( File.isDirectory(screenshot_dir)==0 ){
print("Creating folder "+ screenshot_dir);
File.makeDirectory(screenshot_dir);
}

open(filename);
myimage=getTitle();
selectWindow(myimage);









FindRods(myimage,results_dir);

// Close all result images"
close("*Result*");
}

//////////////////////////
/// Function definition:   GEOMETRIC_LINEARITY_TEST
function FindRods(name,results_dir) {
selectWindow(name);	


run("Duplicate...", "duplicate");
rename("dup1");
run("Make Binary", "method=Minimum background=Dark calculate black");
run("Make Binary", "method=Minimum calculate black");

run("Duplicate...", "duplicate");
rename("dup2");
run("Invert", "stack");
run("Fill Holes", "stack");
run("Invert", "stack");

	run("Calculator Plus", "i1=dup2 i2=dup1 operation=[Subtract: i2 = (i1-i2) x k1 + k2] k1=1 k2=0 create");
	close("dup*");
	selectWindow("Result");
run("Duplicate...", "duplicate");
rename("CandE");
	


//find edge rods
run("Z Project...", "projection=Median");
rename("Flat");

  
// particles	
selectWindow("Flat");	
run("Invert");
run("Set Measurements...", "centroid shape stack display redirect=None decimal=2");
run("Analyze Particles...", "size=1-20 circularity=0.01-1.00 exclude clear");

xpos=newArray(4);
ypos=newArray(4);
posind=newArray(4);
for (i = 0; i < 4; i++) {
	xp=getResult("X", i);
	yp=getResult("Y", i);
	xpos[i]=xp;
	ypos[i]=yp;

	posind[i]=yp*10+xp;
}

sort_index=Array.rankPositions(posind);


Array.print(xpos);
Array.print(ypos);
Array.print(posind);
Array.print(sort_index);

xpos2=newArray(4);
ypos2=newArray(4);
for (i = 0; i < 4; i++) {
	xpos2[i]=xpos[sort_index[i]];
	ypos2[i]=ypos[sort_index[i]];
}
xpos=xpos2;
ypos=ypos2;
xpos_ypos_concat=Array.concat(xpos,ypos);


// rectangle
selectWindow("CandE");
roiManager("reset")

//makePolygon(xpos[0]-10, ypos[0]-10, xpos[1]+10, ypos[1]-10,xpos[3]+10, ypos[3]+10, xpos[2]-10, ypos[2]+10);
makePolygon(xpos[0]-5, ypos[0]-5, xpos[1]+5, ypos[1]-5,xpos[3]+5, ypos[3]+5, xpos[2]-5, ypos[2]+5);
roiManager("add");
roiManager("Select", 0);

run("Make Inverse");
run("Clear", "stack");
roiManager("Show All");

// create copies for centre and edge rods
run("Duplicate...", "duplicate");
rename("centreRods");
run("Duplicate...", "duplicate");
rename("edgeRods");


roiManager("reset")
makeOval(xpos[0]-15, ypos[0]-15, 30, 30);
roiManager("add");
makeOval(xpos[1]-15, ypos[1]-15, 30, 30);
roiManager("add");
makeOval(xpos[2]-15, ypos[2]-15, 30, 30);
roiManager("add");
makeOval(xpos[3]-15, ypos[3]-15, 30, 30);
roiManager("add");
roiManager("Select", newArray(0,1,2,3));
roiManager("Combine");
roiManager("Add");

// Create edgeRods image
selectWindow("edgeRods");
roiManager("Select", 4);
run("Clear Outside", "stack");
run("Select None");
run("Invert", "stack");


// Create centreRods image
selectWindow("centreRods");
roiManager("Select", 4);
run("Clear", "stack");
run("Select None");
run("Invert", "stack");


// Find all rods 
roiManager("reset");

kk=0;
slice=newArray(nSlices);
selectWindow("CandE");
run("Invert", "stack");

for (i = 0; i < nSlices; i++) {
	//run("Previous Slice [<]");
	setSlice(i+1);
	//run("Duplicate...", "use");
	wait(10);
	run("Analyze Particles...", "size=1-30 circularity=0.01-1.00 exclude summarize slice clear");
	
	counts = nResults(); 
	print(counts);
//	wait(500);
	if (counts == 6) {
	slice[kk]=i+1;
	kk=kk+1;
	};
	

	};

print("Pre-cleaned slices with 6 results are:");
Array.print(slice);

// make sure the slices are contiguous
dif = newArray(slice.length-1);	
for (i=0; i<slice.length-1; i++) {
	dif[i] = slice[i+1] - slice[i];
	};

for (i=0; i<dif.length-1; i++) {
	if (dif[i] != 1) {
		slice = Array.slice(slice,0,i+1);
		i = 1000;
		}
	};


print("The slices to take measures from are:");
Array.print(slice);



// measure the distance between edge rods (control)
xpos=newArray(4);
ypos=newArray(4);
roiManager("reset");


for (i=0; i<slice.length ; i++) {
	selectWindow("edgeRods");
	wait(20);
	setSlice(slice[i]);
	wait(20);
	run("Analyze Particles...", "size=1-30 circularity=0.01-1.00 exclude summarize slice clear");
			
	for (j = 0; j < 4; j++) {
	xp=getResult("X", j);
	yp=getResult("Y", j);
	xpos[j]=xp;
	ypos[j]=yp;
	};
	
	
	selectWindow(myimage);
	wait(20);
	setSlice(slice[i]);
	wait(20);
	
	makeLine(xpos[0], ypos[0], xpos[1], ypos[1]);
	roiManager("add");
	makeLine(xpos[2], ypos[2], xpos[3], ypos[3]);
	roiManager("add");	
//	roiManager("update");

}


   
		//setLocation(1,1,1028,1028);
		//wait(50);
		//myscreenshot=screenshot_dir+File.separator+myimage+"_sl"+(i+1)+".png";
		//exec("screencapture", myscreenshot);
		//setLocation(1,1,300,300);
	
	

//
//roiManager("Deselect");
//roiManager("Measure");
//setResult("control1", 1, getResult("Length",0));
//setResult("control2", 1, getResult("Length",1));
//updateResults;


//// Now the centreRods
xpos2=newArray(2);
ypos2=newArray(2);



for (i=0; i< slice.length; i++) {
	selectWindow("centreRods");  
	setSlice(slice[i]);
    run("Analyze Particles...", "size=1-30 circularity=0.01-1.00 exclude summarize slice clear");

//	run("Analyze Particles...", "size=1-20 slice ");
	for (j=0; j< 2; j++) {
	xp2=getResult("X", j);
	yp2=getResult("Y", j);
	xpos2[j]=xp2;
	ypos2[j]=yp2;
	};
	


	selectWindow(myimage);
	setSlice(slice[i]);
	
	makeLine(xpos2[0], ypos2[0], xpos2[1], ypos2[1]);
	roiManager("add");
	roiManager("update");


};







roiManager("select", Array.getSequence(roiManager("count")));
roiManager("Show None");
//roiManager("update");
//roiManager("deselect");

roiManager("Measure");


len=newArray(nResults);
for (i = 0; i < nResults; i++) {
len[i]=getResult("Length", i);

};
//print("nResults:");
  //  print(nResults);

    
//print("len:");
  //  Array.print(len);

    run("Clear Results");
 for (i=0; i<len.length/3; i++){
 
      setResult("DiagLength", i, len[i+2*len.length/3]);
      setResult("AverageControl", i, 0.5*(len[i+1]+len[i]));
      setResult("Control1", i, len[i]);
      setResult("Control2", i, len[i+1]);
  
  }
updateResults;
  
saveAs("Results", outdir+File.separator+myimage+"_SLICE_POS.csv");
//////////



/////Screen-shots
selectWindow(myimage);
wait(40);
nROIs = roiManager("count");
for (i=0; i<nROIs; i++){
		
		roiManager("Select", i);
//		setSlice(slice[i]);
		setLocation(1,1,800,800);
		
//		setLocation(1,1,300,300);
		wait(40);
		myscreenshot=screenshot_dir+File.separator+myimage+"_rod"+(i+1)+".png";
//		print(myscreenshot);
		exec("screencapture", myscreenshot);
//		setLocation(1,1,300,300);
		};


return xpos_ypos_concat;




};

};
