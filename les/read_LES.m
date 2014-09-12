clear;
close all;

base_dir=pwd;
% data_dir='/Users/alexlyakhov/Desktop/LES/suct_vort';
data_dir='suct_vort';
% data_dir='twocell';

v0=250; %This is the characteristic velocity, which scales the non-dimensional model results.  
%Common values for the two-cell vortex are 150 and 225 m/s.
%Suggested value for the suction vortex case is 250 m/s.
g=9.8;

%LES file name
LES_name='LES_mean_1_6_fnum1.dat';

num_times=10;

%Spatial dimensions are scaled by a factor of v0^2/9.8, so increasing the
%non-dimensional velocity scale increases the domain size.  Time also
%increases with increasing velocity scale by a factor of v0/g.

%%%%%%%%%%%%%%%%%%%%%%%%
% Read in the LES grid %
%%%%%%%%%%%%%%%%%%%%%%%%

% cd(data_dir)
fid=fopen([data_dir, '/fort.10_2'],'r','ieee-le');
junk=fread(fid,1,'int');
Nx=fread(fid,1,'int');
Ny=fread(fid,1,'int');
Nz=fread(fid,1,'int');
junk=fread(fid,2,'real*4');
Xc=fread(fid,Nx*Ny*Nz,'real*4');
junk=fread(fid,2,'real*4');
Yc=fread(fid,Nx*Ny*Nz,'real*4');
junk=fread(fid,2,'real*4');
Zc=fread(fid,Nx*Ny*Nz,'real*4');
%Dimensionalize variables
Xc=squeeze(Xc(1:Nx));
Yc=Xc;
Zc=squeeze(Zc(1+(Nx-1)*(Ny-1):(Nx-1)*(Ny-1):(Nz)*(Nx-1)*(Ny-1)+1));
Xc=Xc*v0^2/9.80;
Yc=Yc*v0^2/9.80;
Zc=Zc*v0^2/9.80;
%Original values of Xm, Ym, Zm are the grid cell edges.  So, we need the
%position of the grid cell centers
% xc=(Xc(2:max(size(Xc)))+Xc(1:max(size(Xc))-1))/2;
% yc(1,1:Ny-1)=(Yc(2:max(size(Yc)))+Yc(1:max(size(Yc))-1))/2;
% zc(1,1,1:Nz-1)=(Zc(2:max(size(Zc)))+Zc(1:max(size(Zc))-1))/2;
xc=Xc(1:max(size(Xc))-1);
yc=permute(Yc(1:max(size(Yc))-1), [2 1]);
zc=permute(Zc(1:max(size(Zc))-1), [3 2 1]);
Xm=repmat(xc,[1 Ny-1 Nz-1]);
Ym=repmat(yc,[Nx-1 1  Nz-1]);
Zm=repmat(zc,[Nx-1 Ny-1 1]);
fclose(fid);

%LES data is only stored in a subdomain where the tornado is located
ix1=15; ix2=Nx-16; %minimum and maximum (x,y,z) values of indices saved
iy1=15; iy2=Nx-16;
iz1=1; iz2=51;

Xmf=Xm(ix1:ix2,iy1:iy2,iz1:iz2); %Reconstruct grid only for saved data pts
Ymf=Ym(ix1:ix2,iy1:iy2,iz1:iz2);
Zmf=Zm(ix1:ix2,iy1:iy2,iz1:iz2);

%%%%%%%%%%%%%%%%%%%%%%%%
% Read in the LES file %
%%%%%%%%%%%%%%%%%%%%%%%%

fid=fopen([data_dir, '/', LES_name],'r','ieee-le');
tmp=fread(fid, 1, 'int');

for kdx=1:num_times
    time(kdx)=fread(fid,1,'real*4')*v0/g;
    tmp=fread(fid,2,'int');
    u=single(fread(fid,max(size(Xmf(:))),'real*4'))*v0;
    tmp=fread(fid,2,'int');
    v=single(fread(fid,max(size(Xmf(:))),'real*4'))*v0;
    tmp=fread(fid,2,'int');
    w=single(fread(fid,max(size(Xmf(:))),'real*4'))*v0;
    tmp=fread(fid,2,'int');
    p=single(fread(fid,max(size(Xmf(:))),'real*4'))*v0^2;
    tmp=fread(fid,2,'int');
    %     pstore(1:xsize,1:xsize,1:zsize,kdx)=p(xtmp,ytmp,ztmp);
    tke=single(fread(fid,max(size(Xmf(:))),'real*4'))*v0^2;
    tmp=fread(fid,2,'int');
    %     tkestore(1:xsize,1:xsize,1:zsize,kdx)=tke(xtmp,ytmp,ztmp);
    u=reshape(u,size(Xmf,1),size(Xmf,2),size(Xmf,3));
    v=reshape(v,size(Xmf,1),size(Xmf,2),size(Xmf,3));
    w=reshape(w,size(Xmf,1),size(Xmf,2),size(Xmf,3));
    p=reshape(p,size(Xmf,1),size(Xmf,2),size(Xmf,3));
    tke=reshape(tke,size(Xmf,1),size(Xmf,2),size(Xmf,3));

    ustore(1:size(Xmf,1),1:size(Xmf,2),1:size(Xmf,3),kdx)=u; 
    vstore(1:size(Xmf,1),1:size(Xmf,2),1:size(Xmf,3),kdx)=v;
    wstore(1:size(Xmf,1),1:size(Xmf,2),1:size(Xmf,3),kdx)=w;
    tkestore(1:size(Xmf,1),1:size(Xmf,2),1:size(Xmf,3),kdx)=tke;
    clear u v w p tke
end
fclose(fid)
cd(base_dir)

lev=5; %z index to plot
tme=5; %time index to plot
figure(1)
subplot(2,2,1)
pcolor(squeeze(double(Xmf(:,:,lev))),squeeze(double(Ymf(:,:,lev))),squeeze(double(ustore(:,:,lev,tme))))
shading flat
colorbar
xlabel('X(m)')
ylabel('Y(m)')
title('U (m/s)')
subplot(2,2,2)
pcolor(squeeze(double(Xmf(:,:,lev))),squeeze(double(Ymf(:,:,lev))),squeeze(double(vstore(:,:,lev,tme))))
shading flat
colorbar
xlabel('X(m)')
ylabel('Y(m)')
title('V (m/s)')
subplot(2,2,3)
pcolor(squeeze(double(Xmf(:,:,lev))),squeeze(double(Ymf(:,:,lev))),squeeze(double(wstore(:,:,lev,tme))))
shading flat
colorbar
xlabel('X(m)')
ylabel('Y(m)')
title('W (m/s)')
subplot(2,2,4)
pcolor(squeeze(double(Xmf(:,:,lev))),squeeze(double(Ymf(:,:,lev))),squeeze(double(tkestore(:,:,lev,tme))))
shading flat
colorbar
xlabel('X(m)')
ylabel('Y(m)')
title('TKE (m^2/s^2)')
