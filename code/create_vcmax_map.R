# script to create a global vcmax map based on "optimal_vcmax_R" repository

## load libs
library(raster)
library(RColorBrewer)
library(maps)
library(mapdata)
library(gridBase)
library(mapproj)
library(grDevices)
library(ncdf4)

## source the optimal_vcmax_R code, available here: https://github.com/SmithEcophysLab/optimal_vcmax_R
source('../../optimal_vcmax_R/calc_optimal_vcmax.R')
sourceDirectory('../../optimal_vcmax_R/functions')

## test the source code
par_seq = calc_optimal_vcmax(paro = seq(100, 1000, 100))

## get climate data
tmp_globe_4model = read.csv('../data/climate/cru_tmp_climExtract_growingseason_globe.csv')
par_globe_4model = read.csv('../data/climate/cru_par_climExtract_growingseason_globe.csv')
vpd_globe_4model = read.csv('../data/climate/cru_vpd_climExtract_growingseason_globe.csv')
z_globe_4model =  read.csv('../data/climate/z_globe.csv')

modis_2001 = raster('../data/modis/LC_hd_global_2001.tif')
modis_2002 = raster('../data/modis/LC_hd_global_2002.tif')
modis_2003 = raster('../data/modis/LC_hd_global_2003.tif')
modis_2004 = raster('../data/modis/LC_hd_global_2004.tif')
modis_2005 = raster('../data/modis/LC_hd_global_2005.tif')
modis_2006 = raster('../data/modis/LC_hd_global_2006.tif')
modis_2007 = raster('../data/modis/LC_hd_global_2007.tif')
modis_2008 = raster('../data/modis/LC_hd_global_2008.tif')
modis_2009 = raster('../data/modis/LC_hd_global_2009.tif')
modis_2010 = raster('../data/modis/LC_hd_global_2010.tif')
modis_2011 = raster('../data/modis/LC_hd_global_2011.tif')
modis_2012 = raster('../data/modis/LC_hd_global_2012.tif')

modis = overlay(modis_2001, modis_2002, modis_2003, modis_2004, modis_2005, 
                modis_2006, modis_2007, modis_2008, modis_2009, modis_2010, 
                modis_2011, modis_2012, fun = mean)
modis[modis == 16] <- 0 #barren
modis[modis > 0] <- 1 # vegetated

## predict Vcmax at each global site
vcmax_pred=calc_optimal_vcmax(tg_c = tmp_globe_4model$tmp, 
                              paro = par_globe_4model$par,
                              vpdo = vpd_globe_4model$vpd, 
                              z = z_globe_4model$z)

## create raster
vcmax_pred_globe = cbind(tmp_globe_4model$lon, tmp_globe_4model$lat, vcmax_pred$vcmax)
vcmax_pred_globe_ras = rasterFromXYZ(vcmax_pred_globe)

## remove barren points
vcmax_pred_globe_ras_modis = vcmax_pred_globe_ras * modis

## plot the map
pale = colorRampPalette(c('white', rev(brewer.pal(10,'Spectral'))))
cols = pale(28)
arg = list(at = seq(0, 135, 15), labels = seq(0, 135, 15))

# par(mfrow=c(1,1), oma=c(4,4,1,2), mar=c(1,1,1,1))
plot(vcmax_pred_globe_ras_modis, 
     col=cols, breaks = seq(0, 140, 5), 
     cex.axis=1.5, yaxt = 'n', xaxt = 'n', 
     lab.breaks = seq(0, 140, 5), ylim = c(-90, 90), 
     legend.args=list(text=expression(italic('V'*"'")[cmax]*' (µmol m'^'-2'*' s'^'-1'*')'), 
                      line = 4, side = 4, las = 3, cex = 1.5), legend = T, 
     xlim = c(-180, 180), axis.args = arg)
map('world',col='black',fill=F, add = T, ylim = c(-180, 180))
axis(2, at = seq(-90, 90, 30), labels = T, cex.axis = 1.5)
axis(1, at = seq(-180, 180, 90), labels = T, cex.axis = 1.5)

## create netcdf output file
crs(vcmax_pred_globe_ras_modis) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
writeRaster(vcmax_pred_globe_ras_modis, '../output/optimal_vcmax_globe.nc', 
            overwrite=TRUE, format="CDF", 
            varname="vcmax", varunit="µmol m-2 s-1", 
            longname="vcmax -- raster layer to netCDF", xname="lon", yname="lat")

## view file
test = brick('../output/optimal_vcmax_globe.nc')
plot(test, 
     col=cols, breaks = seq(0, 140, 5), 
     cex.axis=1.5, yaxt = 'n', xaxt = 'n', 
     lab.breaks = seq(0, 140, 5), ylim = c(-90, 90), 
     legend.args=list(text=expression(italic('V'*"'")[cmax]*' (µmol m'^'-2'*' s'^'-1'*')'), 
                      line = 4, side = 4, las = 3, cex = 1.5), legend = T, 
     xlim = c(-180, 180), axis.args = arg)
map('world',col='black',fill=F, add = T, ylim = c(-180, 180))
axis(2, at = seq(-90, 90, 30), labels = T, cex.axis = 1.5)
axis(1, at = seq(-180, 180, 90), labels = T, cex.axis = 1.5)
