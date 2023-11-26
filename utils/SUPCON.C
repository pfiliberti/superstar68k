/* program to convert Pictor .PIC files to superstar binary format */

#include <stdio.h>
#include <malloc.h>

typedef struct header {
  unsigned int mark;            /* always 01234h */
  unsigned int xsize;           /* x size of page */
  unsigned int ysize;           /* y size of page */
  unsigned int xoff;            /* x offset into picture viewport */
  unsigned int yoff;            /* y offset into picture viewport */
  unsigned char bitsinf;        /* 0-3 bits/pixel/plane, 4-7 planes */
} H_TYPE, *H_PTR;

typedef struct extra {
  unsigned char emark;          /* always 0ffh */
  unsigned char evideo;         /* video mode (0-3, A-O) */
  unsigned int edesc;           /* type of color info */
  unsigned int esize;           /* size of color info */
} E_TYPE, *E_PTR;

char *vid_mode[] = {
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

FILE *fp1,*fp2;
H_TYPE head;
E_TYPE extra;
unsigned int numblks;
unsigned char huge *buff;
long bufsize;

main(argc,argv)
  int argc;
  char *argv[];
{
  FILE *fopen();
  unsigned int info;
  register int x;
  long tmp;

  if (argc != 2) {
    printf("Usage: pic2sup FILENAME.PIC\n");
    exit(-1);
  }

  if ((fp1 = fopen(argv[1],"rb")) == NULL) {
    printf("\nsupcon: can't open file %s\n",argv[1]);
    exit(-1);
  }

  /* read header and extra info */

  fread(&head,1,11,fp1);
  if (head.mark != 0x1234) {
    printf("\nsupcon: %s not a .PIC file\n",argv[1]);
    exit(-1);
  }
  fread(&extra,1,6,fp1);

  printf("Picture was saved as %s\n\n",vid_mode[extra.evideo - 0x41]);
  printf("Picture is %d by %d\n",head.xsize,head.ysize);
  printf("Xoffset = %d Yoffset = %d\n",head.xoff,head.yoff);
  printf("Number of bits per pixel is %d\n",head.bitsinf & 15);
  printf("Number of bit planes is %d\n\n",head.bitsinf /16+1);

  /* write palette file */

  if ((fp2 = fopen("COLOR.ASC","w")) == NULL) {
    printf("\nsupcon: can't create file COLOR.ASC\n");
    fclose(fp1);
    exit(-1);
  } else printf("Writing color file\n");

  for (x = 0; x < extra.esize; x++) {
    info = fgetc(fp1) & 0xff;
    fprintf(fp2,"%d\n",info);
  }
  fclose(fp2);

  /* allocate buffer */

  bufsize = (long) head.xsize * head.ysize;
  if((buff = (char huge *) halloc(bufsize,1)) == NULL) {
    printf("\nsupcon: memory allocation error\n");
    fclose(fp1);
    exit(-1);
  }

  /* convert to superstar format (video mode L) */

  fread(&numblks,2,1,fp1);
  for (x = 0; x <= (head.bitsinf / 16); x++) make_plane(x);

  /* write buffer to file */

  if ((fp2 = fopen("SCREEN.BIN","wb")) == NULL) {
    printf("\nsupcon: can't create screen file SCREEN.BIN\n");
    exit(-1);
  }

  /* copy buffer */

  printf("\n(S)uperstar or (P)ictor format >> ");
  if (getchar() == 'P') {
    printf("\n writing new screen file\n");
    head.bitsinf = 8;
    extra.evideo = 'L';
    extra.edesc = 4;
    extra.esize = 768;

    fwrite(&head,11,1,fp2);
    fwrite(&extra,6,1,fp2);
    for (x = 0; x < 256; x++) {
      fputc(x,fp2);
      fputc(x,fp2);
      fputc(x,fp2);
    }
    fputc(0,fp2);
    fputc(0,fp2);
    fwrite(buff,bufsize / 8,8,fp2);

  } else {
    printf("\n writing new screen file\n");
    for (x = 1; x <= head.ysize; x++) {
      tmp = bufsize - (long) x * head.xsize;
      fwrite(buff+tmp,head.xsize,1,fp2);
    }
  }

  fclose(fp1);
  fclose(fp2);
  hfree(buff);
  printf("\n*** conversion complete ***\n");
}


make_plane(plane)
  int plane;
{
  unsigned int x,y,i,mshift,plnblks,blkcnt,pbsize,bsize,run_len;
  unsigned char info,nu_info,mask,mbyte;
  unsigned char huge *ptr;
  long plane_size;

  printf("\n*** processing plane #%d ***\n\n",plane+1);
  plnblks = numblks / ((head.bitsinf / 16) + 1);
  plane_size = ((long) head.xsize * head.ysize / 8) * (head.bitsinf & 15);
  ptr = buff; /* start at beginning of buffer */

  /* make mask for data */

  mask = 0;
  mshift = head.bitsinf & 15;
  for (x = 0; x < mshift; x++) {
    mask = mask / 2;
    mask = mask | 0x80;
  }

  /* do packed blocks */
  if (numblks) {
    for (i = 0; i < plnblks; i++) {
      printf("Block %d of %d: ",i+1,plnblks);
      fread(&pbsize,2,1,fp1);           /* read packed block size */
      fread(&bsize,2,1,fp1);            /* read unpacked size */
      fread(&mbyte,1,1,fp1);            /* read marker byte */
      printf("bsize %u, ",bsize);
      printf("%u to process, ",plane_size);
      blkcnt = 0;

      do {
	fread(&info,1,1,fp1);
	if(info != mbyte) {
	  for (x = 0; x < 8 / mshift; x++) {
	    nu_info = (mask >> (x * mshift)) & info;
	    nu_info = nu_info >> (8-mshift-x*mshift);
	    nu_info = nu_info << (plane * mshift);
	    if (plane == 0) *ptr = nu_info;
	      else *ptr = *ptr | nu_info;
	    ptr++;
	  }
	  blkcnt++;
	} else {
	  fread(&info,1,1,fp1);                 /* 8 bit length */
	  if (!info) fread(&run_len,2,1,fp1);   /* 16 bit length */
	    else run_len = info;
	  fread(&info,1,1,fp1); /* byte to repeat */
	  blkcnt = blkcnt + run_len;
	  for (y = 0; y < run_len; y++)
	    for (x = 0; x < 8 / mshift; x++) {
	      nu_info = (mask >> (x * mshift)) & info;
	      nu_info = nu_info >> (8-mshift-x*mshift);
	      nu_info = nu_info << (plane * mshift);
	      if (plane == 0) *ptr = nu_info;
		else *ptr = *ptr | nu_info;
	      ptr++;
	    }
	}
      } while (blkcnt < bsize);
      printf("%u done...\n",blkcnt);
      plane_size -= blkcnt;
      if(blkcnt > bsize) printf("\nsupcon: block size error\n");
    }
  } else {
    for(y = 0; y < plane_size; y++) {
      fread(&info,1,1,fp1);
      for (x = 0; x < 8 / mshift; x++) {
	nu_info = (mask & info) >> (8 - mshift - x * mshift);
	nu_info = nu_info << (plane * mshift);
	if (plane == 0) *ptr = nu_info;
	  else *ptr = *ptr | nu_info;
	ptr++;
      }
    }
  }
}
