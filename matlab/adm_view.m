% ADM viewer
%
% C = adm_view(filename) returns a structure that contains the drag
% coefficients dx, dy, dz and angular momentum coefficients mx, my, and mz.
%
% Boon Leng Cheong
% Advanced Radar Research Center
% University of Oklahoma
% 2016/02/09
%
function C = adm_view(filename, style)

if ~exist('style', 'var'), style = 1; end

% Open and read the file
fid = fopen(filename, 'r');
if (fid < 0)
    error('Unable to open file');
end
beta_count = fread(fid, 1, 'uint16');
alpha_count = fread(fid, 1, 'uint16');
raw = fread(fid, beta_count * alpha_count * 6, 'float');
fclose(fid);

% Make the angles
xx = (0 : beta_count - 1) / (beta_count - 1) * 360 - 180;
yy = (0 : alpha_count - 1) / (alpha_count - 1) * 180;

% Distribute the data
raw = reshape(raw, [beta_count, alpha_count, 6]);
C.beta_count = beta_count;
C.alpha_count = alpha_count;
C.beta = xx;
C.alpha = yy;
C.dx = raw(:, :, 1).';
C.dy = raw(:, :, 2).';
C.dz = raw(:, :, 3).';
C.mx = raw(:, :, 4).';
C.my = raw(:, :, 5).';
C.mz = raw(:, :, 6).';

% Plots
if style == 0

    for is = 1:6
        switch(is)
            case 1
                im = C.dx;
                tstr = 'dx';
                clim = [-1.5 1.5];
            case 3
                im = C.dy;
                tstr = 'dy';
                clim = [-1.5 1.5];
            case 5
                im = C.dz;
                tstr = 'dz';
                clim = [-1.5 1.5];
            case 2
                im = C.mx;
                tstr = 'mx';
                clim = [-0.15 0.15];
            case 4
                im = C.my;
                tstr = 'my';
                clim = [-0.15 0.15];
            case 6
                im = C.mz;
                tstr = 'mz';
                clim = [-0.15 0.15];
        end

        subplot(3, 2, is)
        imagesc(xx, yy, im)
        axis([-180 180 0 180])
        caxis(clim)
        colorbar
        xlabel('Beta (deg)')
        ylabel('Alpha (deg)')
        set(gca, 'YDir', 'Normal')
        title(tstr)
    end

elseif style == 1
    
    % Shading faceted will look nicer with this grid system
    %xx = (-0.5 : beta_count - 1) / (beta_count - 1) * 360 - 180;
    %yy = (-0.5 : alpha_count - 1) / (alpha_count - 1) * 180;
    % [mbeta, malpha] = meshgrid(deg2rad(xx), deg2rad(yy));
    
    clf
    
    plate = [-1 1 1 -1 -1; 0 0 0 0 0; -1 -1 1 1 -1; 0 0 0 0 0] * 1.2;
    
    [mbeta, malpha] = meshgrid(deg2rad(C.beta), deg2rad(C.alpha));

    y = cos(mbeta);
    x = sin(mbeta) .* sin(malpha);
    z = sin(mbeta) .* cos(malpha);

    ha = zeros(1, 6);
    hc = zeros(1, 2);
    
    theta = linspace(0, 2 * pi, 30);
    rx = sin(theta);
    ry = zeros(size(theta));
    rz = cos(theta);
    
%     vp = get(gcf, 'UserData');
%     if ~isempty(vp) && isfield('lp', vp)
%         clear(vp.lp);
%     end
    
    for is = 1:6
        switch(is)
            case 1
                im = C.dx;
                tstr = '$c_{\mathrm{D}, x}$';
                clim = [-1.5 1.5];
                arrow = [0 1 0];
            case 2
                im = C.dy;
                tstr = '$c_{\mathrm{D}, y}$';
                clim = [-1.5 1.5];
                arrow = [0 0 1];
            case 3
                im = C.dz;
                tstr = '$c_{\mathrm{D}, z}$';
                clim = [-1.5 1.5];
                arrow = [1 0 0];
            case 4
                im = C.mx;
                tstr = '$c_{\mathrm{M}, x}$';
                clim = [-0.15 0.15];
                arrow = [0 1 0];
            case 5
                im = C.my;
                tstr = '$c_{\mathrm{M}, y}$';
                clim = [-0.15 0.15];
                arrow = [0 0 1];
            case 6
                im = C.mz;
                tstr = '$c_{\mathrm{M}, z}$';
                clim = [-0.15 0.15];
                arrow = [1 0 0];
        end
        
        ha(is) = subplot(2, 3, is);

        surf(x, y, z, im);
        hold on
        fill3(plate(1, :), plate(2, :), plate(3, :), plate(4, :))
        plot3(plate(1, :), plate(2, :), plate(3, :), 'k')
        plot3(rx, ry, rz, 'k')
        quiver3(0, 0, 0, arrow(1), arrow(2), arrow(3), 1.7, 'LineWidth', 2);
        hold off
        title(tstr, 'Interpreter', 'Latex')
        caxis(clim)
        if (is == 3)
            hc(1) = colorbar('horiz', 'EastOutside');
            set(hc(1), 'Position', [0.94 0.55 0.015 0.4])
        elseif (is == 6)
            hc(2) = colorbar('horiz', 'EastOutside');
            set(hc(2), 'Position', [0.94 0.05 0.015 0.4])
        end

        shading interp
        xlabel('$z$', 'Interpreter', 'Latex');
        ylabel('$x$', 'Interpreter', 'Latex');
        zlabel('$y$', 'Interpreter', 'Latex');
        axis equal vis3d
    end
    
    % Keep the handles in figure's userdata
    vp.ha = ha;
    vp.hc = hc;
    vp.lp = linkprop(ha, {'CameraPosition', 'CameraViewAngle'});
    zoom(1.1)
    view(120, 20)
    set(gcf, 'UserData', vp);
    
else
    
    clf
    
    plate = [-1 1 1 -1 -1; 0 0 0 0 0; -1 -1 1 1 -1; 0 0 0 0 0] * 1.2;
    
    [mbeta, malpha] = meshgrid(deg2rad(C.beta), deg2rad(C.alpha));

    y = cos(mbeta);
    x = sin(mbeta) .* sin(malpha);
    z = sin(mbeta) .* cos(malpha);

    ha = zeros(1, 6);
    hc = zeros(1, 2);
    
    theta = linspace(0, 2 * pi, 30);
    rx = sin(theta);
    ry = zeros(size(theta));
    rz = cos(theta);
    
    order = [1 3 5 2 4 6];

    for is = 1:6
        switch(is)
            case 1
                im = C.dx;
                tstr = '$c_{\mathrm{D}, x}$';
                clim = [-1.5 1.5];
                arrow = [0 1 0];
            case 2
                im = C.dy;
                tstr = '$c_{\mathrm{D}, y}$';
                clim = [-1.5 1.5];
                arrow = [0 0 1];
            case 3
                im = C.dz;
                tstr = '$c_{\mathrm{D}, z}$';
                clim = [-1.5 1.5];
                arrow = [1 0 0];
            case 4
                im = C.mx;
                tstr = '$c_{\mathrm{M}, x}$';
                clim = [-0.15 0.15];
                arrow = [0 1 0];
            case 5
                im = C.my;
                tstr = '$c_{\mathrm{M}, y}$';
                clim = [-0.15 0.15];
                arrow = [0 0 1];
            case 6
                im = C.mz;
                tstr = '$c_{\mathrm{M}, z}$';
                clim = [-0.15 0.15];
                arrow = [1 0 0];
        end
        
        ha(is) = subplot(3, 2, order(is));

        surf(x, y, z, im);
        hold on
        fill3(plate(1, :), plate(2, :), plate(3, :), plate(4, :))
        plot3(plate(1, :), plate(2, :), plate(3, :), 'k')
        plot3(rx, ry, rz, 'k')
        quiver3(0, 0, 0, arrow(1), arrow(2), arrow(3), 1.5, 'LineWidth', 3, 'MaxHeadSize', 0.5);
        hold off
        title(tstr, 'Interpreter', 'Latex')
        caxis(clim)
        if (is == 3)
            hc(1) = colorbar('horiz', 'SouthOutside');
            set(hc(1), 'Position', [0.1 0.04 0.35 0.01])
        elseif (is == 6)
            hc(2) = colorbar('horiz', 'SouthOutside');
            set(hc(2), 'Position', [0.6 0.04 0.35 0.01])
        end

        shading interp
        xlabel('$z$', 'Interpreter', 'Latex');
        ylabel('$x$', 'Interpreter', 'Latex');
        zlabel('$y$', 'Interpreter', 'Latex');
        axis equal vis3d
    end
    
    % Keep the handles in figure's userdata
    vp.ha = ha;
    vp.hc = hc;
    vp.lp = linkprop(ha, {'CameraPosition', 'CameraViewAngle'});
    zoom(1.1)
    view(120, 20)
    set(gcf, 'UserData', vp, 'PaperPositionMode', 'Auto');

    if exist('boonlib', 'file')
        boonlib('bsizewin', gcf, [420 640])
    end
end

if nargout == 0, clear C; end

if exist('blib.m', 'file')
    blib('bsizewin', gcf, [600, 300])
end
