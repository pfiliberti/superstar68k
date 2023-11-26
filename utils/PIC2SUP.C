/* program to convert Pictor .PIC files to superstar binary format */

#include <stdio.h>
#include <malloc.h>

FILE    *fp1,*fp2;              /* File Pointers */
struct  {
	unsigned int mark;      /* marks beginning of page file */
	unsigned int xsize;     /* x size of page */
	unsigned int ysize;     /* y size of page */
	unsigned int xoff;      /* x offset into picture viewport */
	unsigned int yoff;      /* y offset into picture viewport */
	unsigned char bitsinf;
	} head;

struct  {
	unsigned char emark;
	unsigned char evideo;
	unsigned int edesc;
	unsigned int esize;
	} extra;

char    *vid_mode[] = {
	"320x200x4 cga",
	"320x200x16 pcjr, stbplus, tandy 1000",
	"640x200x2 cga",
	"640x200x16 ega",
	"640x350x2 ega",
	"640x350x4 ega",
	"640x350x16 ega",
	"720x348x2 hercules",
	"320x200x16 plantronics",
	"320x200x16 ega",
	"640x400x2 at&t or toshiba 3100",
	"320x200x256 vga",
	"640x480x16 ega plus, vga",
	"720x348x16 hercules in color",
	"640x480x2 vga"
	};

unsigned int numblks;

main(argc,argv)
int argc;                           /* Character pointers to and count of */
char *argv[];                         /* command line arguments */
{
unsigned int tmp,x,dsize;
char    byte;

	if (argc < 1)
	{
		printf("Usage pic2sup FILENAME.\n");
		exit(-1);
	}

	fp1 = fopen(argv[1],"rb");  /* open the pic file to be converted */
	if (fp1 == NULL)                 /* If bad file pointer, give up */
	{
	    printf("Cannot open input file!\n");
	    exit(-1);
	}

	fread(&head,1,11,fp1);
	if (head.mark != 0x1234)
	{
		printf("Not a Pic file!\n");
		exit(-1);
	}

	fread(&extra,1,6,fp1);
	tmp=extra.evideo - 0x41;

	printf("Picture was saved as %s\n\n",vid_mode[tmp]);
	printf("Picture is %d by %d\n",head.xsize,head.ysize);
	printf("Xoffset = %d Yoffset = %d\n",head.xoff,head.yoff);
	printf("Number of bits per pixel is %d\n",head.bitsinf & 15);
	printf("Number of bit planes is %d\n\n",head.bitsinf /16+1);


	if(extra.evideo != 'L')
	{
	  printf("Can only convert 256 color VGA pictures for now.\n");
	  exit(-1);
	}

	fp2 = fopen("COLOR.ASC","w"); /* open ascii color file to write */
	if (fp2 == NULL)                 /* If bad file pointer, give up */
	{
	    printf("Cannot open color file COLOR.ASC!\n");
	    exit(-1);
	}
	else    printf("Writing color file\n");

	for(x=0; x < extra.esize; x++)
	{
		fread(&tmp,1,1,fp1);    /* read a color pallete byte */
		tmp=tmp & 0xff;         /* leave only low byte */
		fprintf(fp2,"%d\n",tmp);
	}
	close(fp2);                     /* close ascii color file */

	fp2 = fopen("SCREEN.BIN","wb");/* open binary screen file to write */
	if (fp2 == NULL)                 /* If bad file pointer, give up */
	{
	    printf("Cannot open screen file SCREEN.BIN!\n");
	    exit(-1);
	}
	else    printf("Writing screen file\n");

	fread(&numblks,2,1,fp1);        /* read number if packed blocks */

	if(!numblks)
	{
	   dsize=(head.xsize * head.ysize / 8) * (head.bitsinf & 15);
	   dsize=dsize * (head.bitsinf / 16 + 1);
	   for(x=0; x<dsize; x++)
	   {
		fread(&byte,1,1,fp1);   /* read a byte */
		fputc(byte,fp2);        /* write to screen file */
	   }
	}

	else unpack();

	printf("Conversion complete.");
	fclose(fp1);
	fclose(fp2);
	exit(0);
}

unpack()
{
unsigned int x,y,blkcnt,pbsize,bsize,biglen;
unsigned char tmp,mbyte,length;
unsigned char huge *mem,huge *buffer;
long    offset;

	offset =(long) head.xsize * head.ysize;
	mem = (unsigned char huge *)halloc(offset,1);
	if(mem == NULL)
	{
		printf("Insufficient memory available\n");
		fclose(fp1);
		fclose(fp2);
		exit(-1);
	}

	buffer=mem; /* start at beginning of buffer */

	for(x=0; x<numblks; x++)  /* do for number of blocks */
	{
	   fread(&pbsize,2,1,fp1);  /* read packed block size */
	   fread(&bsize,2,1,fp1);   /* read unpacked size */
	   fread(&mbyte,1,1,fp1);   /* read marker byte */
	   blkcnt=0;                /* zero our block count */

	   do
	   {
		fread(&tmp,1,1,fp1);    /* read a byte */
		if(tmp != mbyte)
		{
			*buffer++=tmp;
			blkcnt++;
		}
		else
		{
			fread(&length,1,1,fp1);  /* read 8 bit length */
			if(!length) fread(&biglen,2,1,fp1);
			else biglen=length;


			fread(&tmp,1,1,fp1);    /* read byte to repeat */
			blkcnt=blkcnt + biglen;

			for(y=0; y<biglen; y++) *buffer++=tmp;

		}
	   } while(blkcnt != bsize);

	   if(blkcnt > bsize) printf("Block Size error!\n");

	}

	buffer=mem;
	for(x=0; x<head.ysize; x++)
	 {

	   offset=(long)head.xsize * head.ysize -((x+1) * (long)head.xsize);
	   buffer=mem + offset;

	   for (y=0; y<head.xsize; y++)
	   {
	      tmp=*buffer++;
	      fputc(tmp,fp2);
	   }
	 }
	 hfree(mem);
}

