% Script to generate global mean theta prime

clear
close all
addpath(genpath('cdt'))
addpath(genpath('colorbrewer'))

load 'DataLL_theta.mat'
load 'LAT2.mat'
load 'LON3.mat'


data = DATAlowLat3;

M = geomean(data,3,'omitnan');

h = imagescn(LON2,LAT2,M);
xticks([45 90 135 180 225 270 315 360])
xticklabels({'45E','90E','135E','180E','135W','90W','45W','0'});
clim([0 4])
colorbar('eastoutside')


colors = flip(brewermap([],"Spectral"));

colormap(colors)

%print('-painters','-dsvg','global_geomean_v5.svg')

