/* PROGRAM TO CONVERT GIF FORMAT PICTURES TO 2 BINARY FILES 1 FOR THE COLOR
TABLE AND ONE FOR THE SCREEN IMAGE */

#include <stdio.h>

FILE	*fp1,*fp2;		/* File pointer for current disk file */
char	gifsig[] = "GIF87a";              /* Gif file signature */
char	finchar,lstblk,gifbuf[512],outcode[1024];
char	suffix[4096];

unsigned int clearcode,eofcode,firstfree,freecode,gifcnt,maxcode,bitoffset;
unsigned int readmask,code,curcode,oldcode,incode,outcount,prefix[4096];
unsigned int codesize,icodesize,bitmask;

main(argc,argv)
int argc;			    /* Character pointers to and count of */
char *argv[];			      /* command line arguments */
{
unsigned int temp;
int	x,swidth,sheight,iwidth,iheight,ileft,itop,ncolor;
char	tmpc,bakcol,interlaced;


	if (argc < 2)
	{
	printf("Need Filename!\n");
	exit(0);
	}

	fp1 = fopen(argv[1],"rb");     /* open the gif file to be converted */
	if (fp1 == NULL)		 /* If bad file pointer, give up */
	{
	    printf("Cannot open input file!\n");
	    exit(0);
	}

	for (x=0;x<6;x++)
	{
	  fread(&tmpc,1,1,fp1);
	  if (tmpc != gifsig[x])
	  {
	    printf("Not a GIF file!\n");
	    exit(0);
	  }
	}

	fread(&swidth,2,1,fp1);
	fread(&sheight,2,1,fp1);
	fread(&tmpc,1,1,fp1);
	if (tmpc & 128 !=128)
	{
	  printf("Global color map not available!\n");
	  exit(0);
	}
	tmpc &= 7;
	ncolor = 2;
	ncolor <<= tmpc;
	bitmask = ncolor - 1;
	printf("Screen is %d by %d by %d colors.\n",swidth,sheight,ncolor);

	fread(&bakcol,1,1,fp1);
	fread(&tmpc,1,1,fp1);		/* read null terminator */

/* Now write color file out in ascii R,G,B format */

	fp2 = fopen("COLOR.ASC","w");     /* open the ascii color file */
	if (fp2 == NULL)		 /* If bad file pointer, give up */
	{
	    printf("Cannot open color file!\n");
	    exit(0);
	}

	for (x=0;x<ncolor*3;x++)
	{
	  fread(&temp,1,1,fp1);
	  temp &= 255;
	  temp = temp * 63;
	  temp = temp / 255;
	  fprintf(fp2,"%d\n",temp);
	}
	fclose(fp2);

/* NOW SEARCH FOR IMAGE DESCRIPTOR */

	tmpc = 0;
	while (tmpc != ',' ) fread(&tmpc,1,1,fp1);

	fread(&ileft,2,1,fp1);
	fread(&itop,2,1,fp1);
	fread(&iwidth,2,1,fp1);
	fread(&iheight,2,1,fp1);
	printf("Image top left is at %d,%d\n",ileft,itop);
	printf("Image is %d by %d\n",iwidth,iheight);

	fread(&tmpc,1,1,fp1);
	if (tmpc & 128 == 128)
	{
	  printf("Cannot do local color maps yet!\n");
	  exit(0);
	}
	interlaced = tmpc & 64;

/* Now start decompressing the data and write the binary screen file */

	fp2 = fopen("SCREEN.BIN","wb");    /* open the binary screen file */
	if (fp2 == NULL)		 /* If bad file pointer, give up */
	{
	    printf("Cannot open screen file!\n");
	    exit(0);
	}

	fread(&codesize,1,1,fp1);		/* init variables */
	clearcode = 1;
	clearcode <<= codesize;
	eofcode = clearcode + 1;
	firstfree = clearcode + 2;
	freecode = firstfree;

	codesize++;
	icodesize = codesize;
	maxcode = 1;
	maxcode <<= codesize;
	readmask = maxcode - 1;

	gifcnt = 0;
	bitoffset = 0;
	lstblk = 0;
	outcount=0;

/* now start by reading blocks into gifbuf */

	blkread();
	printf("Decoding Picture..\n");

/* start decompression loop here */

	do
	{
	readcode();
	if (code != eofcode)
	 {
	  if (code == clearcode)
	  {
		doclear();
		readcode();
		curcode = code;
		oldcode = code;
		finchar = code & bitmask;
		fputc(finchar,fp2);
	  }
	  else
	  {
		curcode = code;    /* if not a clear code then must be data */
		incode = code;

		if (code >= freecode)
		{
		   curcode = oldcode;
		   outcode[outcount] = finchar;
		   outcount++;
		}

		if (curcode > bitmask)
		{
		  while (curcode > bitmask)
		  {
		    outcode[outcount] = suffix[curcode];
		    outcount++;
		    curcode = prefix[curcode];
		  }
		}

		finchar = curcode & bitmask;
		outcode[outcount] = finchar;
		outcount++;

		for (x=outcount;x>0;x--) putc(outcode[x-1],fp2);

		outcount = 0;
		prefix[freecode] = oldcode;
		suffix[freecode] = finchar;
		oldcode=incode;

		freecode++;
		if (freecode >= maxcode)
		{
		  if (codesize < 12)
		  {
		    codesize++;
		    maxcode <<= 1;
		    readmask = maxcode -1;
		  }
		}
	  }
	 }
	} while (code != eofcode);
	printf("Decoding Succesful!\n");
	fclose(fp2);
	exit(0);
}

blkread()
{
unsigned int temp,x;
char tmpc;

	while ((gifcnt < 256) && (lstblk == 0 ))
	{
	  fread(&temp,1,1,fp1); 	/* read block count */
	  temp &=255;
	  if (temp == 0 )
	  {
	    lstblk++;
	  }
	  else
	  {
	    for (x=0; x < temp ; x++)
	    {
	      fread(&tmpc,1,1,fp1);
	      gifbuf[gifcnt] = tmpc;
	      gifcnt++;
	    }
	  }
	}
}

doclear()
{
	codesize = icodesize;
	maxcode = 1;
	maxcode <<= codesize;
	readmask = maxcode - 1;
	freecode = firstfree;
}

readcode()
{
unsigned int byteoffset,x;
long unsigned int ncode;
char tmp,shftamt,*pcode;

  byteoffset = bitoffset / 8;
  shftamt = bitoffset & 7;
  if ((byteoffset >= 256) && (lstblk == 0))
  {
      for (x=256;x<513;x++) gifbuf[x-256]=gifbuf[x];  /* move buffer down */
      byteoffset=byteoffset-256;
      gifcnt=gifcnt-256;
      bitoffset=bitoffset-2048;
      blkread();				/*read more data in */
  }
  pcode=&ncode;
  for (x=0;x<4;x++)
  {
    *pcode = gifbuf[byteoffset+x];
    pcode++;
  }
  ncode >>= shftamt;
  code = ncode & 65535;
  code = code & readmask;
  bitoffset = bitoffset + codesize;
}
