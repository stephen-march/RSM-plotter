function [] = RSM_plot( params_file,data_file )
% To print the figure and preserve the background colors, use:
%   fig = gcf;
%   fig.InvertHardcopy = 'off';
%   saveas(gcf,'print_test.png'); % change the file name...
%

%% Some ideas for future code
% pass the params and data files in as arguments
% if no arguments, pull up the click menu for the RSM text file, which then
% is used to call the perl script to generate the params and data files
% before continuing the rest of this script

%% Read input files
params = csvread(params_file);
data = csvread(data_file);

%% convert omega and two theta to Qx and Qz

wavelength = params(1,1);
omega = params(2,1);
twoTheta = params(3,1);

k0 = 20 .* pi ./ wavelength; % inverse nm
Qx_origin = k0 .* (cos(pi ./ 180 .* omega) - cos(pi ./180 .* (twoTheta - omega)));
Qz_origin = k0 .* (sin(pi ./ 180 .* omega) + sin(pi ./ 180 .* (twoTheta - omega)));

%% Offset the all the relative Qx and Qz data
% NOTE: for a symmetric scan, Qx will be zero since twoTheta = 2*omega

Qx_relative = data(:,1);
Qz_relative = data(:,2);

% make the origins column matrices
[row,col] = size(Qx_relative);
Qx_origin = ones(col,1)*Qx_origin;
Qz_origin = ones(col,1)*Qz_origin;

Qx_absolute = Qx_relative + Qx_origin;
Qz_absolute = Qz_relative + Qz_origin;

maxQx = max(Qx_absolute);
minQx = min(Qx_absolute);
maxQz = max(Qz_absolute);
minQz = min(Qz_absolute);

%% set up data to plot 

% Get data for the intensity 
V = data(:,3);
V = log10(V);

% Set up interpolant meshgrid
resolution = 0.001;
QX = linspace(minQx,maxQx,1/resolution);
QZ = linspace(minQz,maxQz,1/resolution);
[X,Z] = meshgrid(QX,QZ);

Qx1 = Qx_absolute(1:1:end);
Qz1 = Qz_absolute(1:1:end);

% create a scattered interpolant of the intensity data
% based on the meshgrid
% Note: F acts like a function, so feed in the X and Z data to
% generate a plot for the specified points
F = scatteredInterpolant(Qx1,Qz1,V);
new_data = F(X,Z);

%% Plot 
% NOTE: need MATLAB 2014B or later to use the dot figure operations

% some plotting parameters
axis_on = 1; % 1=x,y labels on, 2=x,y labels off
grid_and_z_off = 1; % 1 = remove the z axis and background grid
transparency = 1; % 0=clear to 1=opaque
all_font_size = 16;


figure;

% set up the color map style
%colormap(jet(2048));
colormap(hot(2048));

% change the color bar starting values for colors
clow = 0; % 10^{clow}
chigh = 3; % 10^{chigh}
caxis([clow,chigh]);



surf(X,Z,new_data,'EdgeColor','none','FaceColor','interp','FaceAlpha',transparency);
%axis off;
set(gca,'ZTick',[]); %suppress the z axis
grid off;
view([-57.7 26.8]);
xlim([minQx maxQx])
ylim([minQz maxQz])
zlim([0.3,chigh]); % log10(2) ~ 0.3, so using it as the lower limit 

% set up the color bar log labels
% need MATLAB 2014b or later for axis formatting, e.g. colorbar function
actual_tick_values = 0:1:5; % orders of magnitude, e.g. 2 --> 10^2
cbar = colorbar('Ticks',actual_tick_values,...
         'TickLabels',{'10^{0}','10^{1}','10^{2}','10^{3}','10^{4}','10^{5}'},...
         'TickLabelInterpreter','tex', ...
         'FontSize',all_font_size,...
         'Location','westoutside',...
         'Color','k');


% Set up all non-inset font labels
LabelText = 'Counts';
ylabel(cbar,LabelText,'FontSize',all_font_size);
xlabel('Q_{||} (nm^{-1})','FontSize',all_font_size);
% xlabel('x position (\mum)','rot',84) % use if you decide to rotate the plot
ylabel('Q_{\perp} (nm^{-1})','FontSize',all_font_size);
ax = gca;
ax.XAxis.Color = 'k';
ax.YAxis.Color = 'k';
     
% set the plot background colors
set(gca,'Color',[0.25,0.25,0.25]); % plot area dark grey
set(gcf,'Color',[1,1,1]); % plot background white

% Add inset of the top view
axes('Position',[.7 .7 .2 .2])
box on
numPoints = 100.*floor(sqrt(length(Qx_absolute))/100)+1;
QX = linspace(minQx,maxQx,numPoints);
QZ = linspace(minQz,maxQz,numPoints);
[X,Z] = meshgrid(QX,QZ);
Vq = griddata(Qx1,Qz1,V,X,Z);
surf(X,Z,Vq,'EdgeColor','none');
view([0,0,1]);
xlim([minQx maxQx])
ylim([minQz maxQz])
small_font_size = 12;
xlabel('Q_{||} (nm^{-1})','FontSize',small_font_size,'Color','w');
ylabel('Q_{\perp} (nm^{-1})','FontSize',small_font_size,'Color','w');
ax = gca;
ax.XAxis.Color = 'w';
ax.YAxis.Color = 'w';

% printing to preserve the background colors
% need at least MATLAB 2014b or later for dot notation
% if using an earlier version, use 'set' commands
%fig = gcf;
%fig.InvertHardcopy = 'off';
%saveas(gcf,'print_test.png'); % change the file name...

end