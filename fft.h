#include <math.h>

//#ifndef FOURIER_H
//#define FOURIER_H
inline void SWAP(float &a, float &b)
	{float dum=a; a=b; b=dum;}
void fft(float* reales, float* imaginarios, int n, int isign) {
  int m, i, mmax, istep;
  float wtemp,wr,wpr,wpi,wi,theta,tempr,tempi;
  
  int j=0;
  // ordenamos con reversed byte order
  for (i = 0; i < n; i++) {
    if (j > i) {
      SWAP(reales[i], reales[j]);
      SWAP(imaginarios[i], imaginarios[j]);
    }
    m = n >> 1;
    while (m >= 1 && j >= m) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }
  
  // fourier propiamente dicho
  mmax = 1;
  while (n > mmax) {
    istep=mmax << 1;
		theta=isign*(6.28318530717959/istep);
		wtemp=sin(0.5*theta);
		wpr = -2.0*wtemp*wtemp;
		wpi=sin(theta);
		wr=1.0;
		wi=0.0;
		for (m=0;m<mmax;m++) {
			for (i=m;i<n;i+=istep) {
				j=i+mmax;
				tempr=wr*reales[j]-wi*imaginarios[j];
				tempi=wr*imaginarios[j]+wi*reales[j];
				reales[j]=reales[i]-tempr;
				imaginarios[j]=imaginarios[i]-tempi;
				reales[i] += tempr;
				imaginarios[i] += tempi;
			}
			wr=(wtemp=wr)*wpr-wi*wpi+wr;
			wi=wi*wpr+wtemp*wpi+wi;
		}
		mmax=istep;
  }
  
}

//#endif
