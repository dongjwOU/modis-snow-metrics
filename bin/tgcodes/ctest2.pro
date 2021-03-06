;PRO ctest2, file
;
;  this is just a quick program to calculate the cloud mask
;  and show clouds and band 1
;
openr,1,"~/ctest.file"
file = ""
readf,1, file
close,1
print, "FILE = ",file


jd = file2jul(file, year=1996)
tfile="~/idl/bin/avhrr/clavrdir/tg96.dat"
TData = ReadThresh(tfile)
tgc = tdata.tgc
ndv = tdata.ndv
dat = [-15,15, 46, 74,  105,135,166,196,227,  258,288,319,349,380]

ndvthresh = interpol(ndv, dat, jd)

data = imgread3(file, 512,512,11, /i2)
datau = avhrrunscale(data, /i2, /ref)
;clavr2, datau, clouds2, jd, tfile=tfile
clouds2 = data(*,*,10)

kernal = replicate(1., 3, 3)
clouds = dilate(clouds2, kernal)


ttop = interpol(tgc, dat, jd)

showimg, clouds, 4
showimg, alog(data(*,*,0)), 5


notcloud = where(clouds eq 0)
cmask = mask(clouds, notcloud, /show)
t4 = datau(*,*,3)
t5 = datau(*,*,4)
nd = datau(*,*,5)

t = tavhrr(t4,t5,4)

t4 = t

idx = uniqpair(t4, nd)
clearidx = uniqpair(t4(notcloud), nd(notcloud))

histo = myhist2d(t4, nd, xser, yser, $
        bin1 = 1, bin2 = 0.02, min1 = 270, min2 = -0.4,$
        max1 = 340, max2 = 0.8)


t4i = data(*,*,3)
ndi = data(*,*,5)



;
;  Try to get Tmin
;
;print, "TTOP =", ttop(0)
watidx = where(nd lt 0 and t4 gt ttop(0) and clouds eq 0, nwatidx)
watthist = hist(t4(watidx), x, binsize=0.2)
gtzeroidx = where (watthist gt 0)
yfit = gaussfit(x, watthist, a, nterms=3)
wattavg = total(x*watthist)/total(watthist)
TMIN = wattavg-a(2)*3.
TMIN = wattavg - 3
TMIN2 = percentile(t4(watidx), 1.0)
;print, tmin

t4idx = where(clouds eq 0 and nd ge ndvthresh(0))
Ncoefs = fitedge(nd(t4idx), t4(t4idx), 0, 0.5, DataToFit, Yfit=Tminedge)
tmin=tminedge(0)


;
; Try to get ND max
;
ndidx = where(nd gt 0 and t4 gt ttop(0) and clouds eq 0 $
              and nd lt 1, nndidx)
NDMAX = percentile(nd(ndidx), 99.9)

tmaxnd = avg(t4(where(nd eq max(nd(where(nd ne max(nd)))))))
ndidx2 = where(nd gt 0 and t4 ge tmaxnd-3 and t4 le tmaxnd+3 $
              and clouds eq 0 $
              and nd lt 1, nndidx)


NDMAX2 = percentile(nd(ndidx2), 99.9)


;
; Try to get ND min
;
;ndidx = where(nd gt 0 and clouds eq 0 and t4 gt wattavg )
ndidx = where(nd gt 0 and t4 gt wattavg)
Ncoefs = fitedge(t4(ndidx), nd(ndidx), 0, 0.5, DataToFit, Yfit=ndmin)


;
; Try to get Tmax
;
tmaxidx = where(nd gt 0 and clouds eq 0 and t4 gt Tmin)
;Tcoefs = fitedge(t4(tmaxidx), nd(tmaxidx), 2, 99.5, TMaxDataToFit, Yfit=tmax)
TMaxDataToFit = WarmEdge(t4(tmaxidx), nd(tmaxidx),99.5)
n = n_elements(TMaxDataToFit(0,*))
w = fltarr(n)+1.0
;w2 = hist(t4(tmaxidx), w2x)  ;THIS WEIGHTING DOESN"T WORK ON FIRST SCENE
;w = w2(where(w2 gt 0))

Tcoefs = PolyFitW(TMaxDataToFit(0,*), TMaxDataToFit(1,*), W,2, TMax)
tmpcoefs = tcoefs
tmpcoefs(0) = tcoefs(0)-ndmin(0)
tmax2 = quadratic(tmpcoefs, /negroot)


;TRY AGAIN TO GET TMIN
t4idx = where(clouds eq 0 and nd ge avg([ndvthresh(0),ndmax2]))
Ncoefs = fitedge(nd(t4idx), t4(t4idx), 0, 0.1, DataToFit, Yfit=Tminedge)
tmin=tminedge(0)


;
; Plot 'em all
;
!p.multi=[0,1,3]
window, 6, xs = 500, ys = 1000

plot, t4(idx), nd(idx), psym=3, xrange=[270, 340], yrange=[-0.4, 0.8], $
      /xstyle, /ystyle, /nodata
oplot, t4(notcloud(clearidx)), nd(notcloud(clearidx)), psym=3, $
      color = rgb(255,255,128)
oplot, [tmin,tmin], [-0.4,0.8]
;oplot, [tmin2,tmin2], [-0.4,0.8], line = 1
;oplot, [min(xser), max(xser)], [NDMAX, NDMAX], line=1
oplot, [min(xser), max(xser)], [NDMAX2, NDMAX2]
oplot, [min(xser), max(xser)], [ndmin(0), ndmin(0)]
oplot, TMaxDataToFit(0,*), TMax
oplot, [tmax2,tmax2], [-0.4,0.8]



imageplot, alog(histo+1), xser, yser, xmax = 340.
oplot, [tmin,tmin], [-0.4,0.8]
;oplot, [tmin2,tmin2], [-0.4,0.8], line = 1
;oplot, [min(xser), max(xser)], [NDMAX, NDMAX], line=1
oplot, [min(xser), max(xser)], [NDMAX2, NDMAX2]
oplot, [min(xser), max(xser)], [ndmin(0), ndmin(0)]
oplot, TMaxDataToFit(0,*), TMax
oplot, [tmax2,tmax2], [-0.4,0.8]

oplot, [min(yser), max(yser)], [tminedge(0), tminedge(0)], line = 0, $
color=rgb(255,255, 128)

;window,7, xs = 400, ys = 300
imageplot, histo, xser, yser, xmax = 340.
oplot, [tmin,tmin], [-0.4,0.8]
;oplot, [tmin2,tmin2], [-0.4,0.8], line = 1
;oplot, [min(xser), max(xser)], [NDMAX, NDMAX], line=1
oplot, [min(xser), max(xser)], [NDMAX2, NDMAX2]
oplot, [min(xser), max(xser)], [ndmin(0), ndmin(0)]
oplot, TMaxDataToFit(0,*), TMax
oplot, [tmax2,tmax2], [-0.4,0.8]

;window,8, xs = 400, ys = 300


!p.multi = [0,1,1]


PRINT, "FILE = ",file, " JD = ", jd
PRINT, "NDMin = ", ndmin(0)
PRINT, "NDMax = ", ndmax2
PRINT, "TMin  = ", Tmin
PRINT, "TMax  = ", TMax2


end
