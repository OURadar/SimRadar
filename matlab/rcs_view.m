% RCS viewer
%
% C = rcs_view(filename) returns a structure that contains the rcs values.
%
% Boon Leng Cheong
% Advanced Radar Research Center
% University of Oklahoma
% 2016/02/09
%
function S = rcs_view(filename, style)

if ~exist('style', 'var'), style = 1; end

if style == 1
    nrow = 1;
elseif style == 2 || style == 3
    nrow = 2;
else
    nrow = 0;
end

fid = fopen(filename, 'r');
if (fid < 0)
    error('Unable to open file');
end

alpha_count = fread(fid, 1, 'uint16');
beta_count = fread(fid, 1, 'uint16');
table = fread(fid, 'float');
fclose(fid);

if numel(table) ~= alpha_count * beta_count * 3 * 2
    fprintf('ERROR. Table elements not consistent.\n')
    fprintf('beta_count = %d  alpha_count = %d   numel = %d vs expected %d\n', ...
        alpha_count, beta_count, numel(table), alpha_count * beta_count * 3 * 2);
    if nargout > 0
        S = [];
    end
    return
end

table = reshape(table, [alpha_count, beta_count, 3, 2]);
table = table(:, :, :, 1) + 1i * table(:, :, :, 2);

alpha_list = (0 : alpha_count - 1) * 2 * pi / (alpha_count - 1) - pi;
beta_list = (0 : beta_count - 1) * pi / (beta_count - 1);

[alphas, betas] = meshgrid(alpha_list, beta_list);

xx = sin(betas) .* cos(alphas); %u cos
yy = sin(betas) .* sin(alphas); %v cos
zz = cos(betas);                %w cos

S.alpha_count = alpha_count;
S.beta_count = beta_count;
S.alphas = alphas;
S.betas = betas;
S.hh = squeeze(table(:, :, 1)).';
S.vv = squeeze(table(:, :, 2)).';
S.hv = squeeze(table(:, :, 3)).';

% S.vv = conj(S.vv);

% Scale and offset from value into table index (same as RS framework)
beta_s = beta_count / pi            ;    beta_o = 0;
alpha_s = alpha_count / (2 * pi)    ;    alpha_o = -(-pi) * alpha_s;
S.alpha_index = @(alpha) alpha * alpha_s + alpha_o;
S.beta_index = @(beta) beta * beta_s + beta_o;

hh = zeros(size(S.hh));
vv = zeros(size(S.hh));
hv = zeros(size(S.hh));
gammas = -alphas;
for ii = 1:numel(gammas)
    gamma = gammas(ii);
    T = [cos(gamma) sin(gamma); -sin(gamma) cos(gamma)];
    Tinv = T.';
    Sc = [S.hh(ii) S.hv(ii); S.hv(ii) S.vv(ii)];
    Sp = Tinv * Sc * T;
    hh(ii) = Sp(1);
    vv(ii) = Sp(4);
    hv(ii) = Sp(2);
end

S.hh_look = hh;
S.vv_look = vv;
S.hv_look = hv;

if style == 0
    return;
end


%% Plots

if style == 1
    clim = [-80 -20];
else
    clim = [0 1];
end

mscale = 20.0;
shading_mode = 'flat';

clf
ha = subplot(nrow, 3, 1);
if style == 2
    surf(xx, yy, zz, mscale * abs(S.hh));
elseif style == 3
    surf(xx, yy, zz, mscale * abs(S.hh_look));
else
    surf(xx, yy, zz, 20 * log10(abs(S.hh)));
end
shading(shading_mode)
xlabel('x'); ylabel('y'); zlabel('z');!
caxis(clim)
title('Shh')

ha(2) = subplot(nrow, 3, 2);
if style == 2
    surf(xx, yy, zz, mscale * abs(S.vv));
elseif style == 3
    surf(xx, yy, zz, mscale * abs(S.vv_look));
else
    surf(xx, yy, zz, 20 * log10(abs(S.vv)));
end
shading(shading_mode)
xlabel('x'); ylabel('y'); zlabel('z');
caxis(clim)
title('Svv')

ha(3) = subplot(nrow, 3, 3);
if style == 2
    surf(xx, yy, zz, mscale * abs(S.hv));
elseif style == 3
    surf(xx, yy, zz, mscale * abs(S.hv_look));
else
    surf(xx, yy, zz, 20 * log10(abs(S.hv)));
end
shading(shading_mode)
xlabel('x'); ylabel('y'); zlabel('z');
caxis(clim)
title('Svh & Shv')
if style == 2 || style == 3
    hc = colorbar('horiz');
    set(hc, 'Position', [0.25 0.52 0.5, 0.02])
else
    hc = colorbar('horiz');
    Sc = get(ha(1), 'Position');
    set(hc, 'Position', [0.25, Sc(2), 0.5, 0.03])
end

if style >= 2
    ha(4) = subplot(2, 3, 5);
    if style == 3
        surf(xx, yy, zz, 20 * log10(abs(S.hh_look) ./ abs(S.vv_look)));
    elseif style == 2 
        surf(xx, yy, zz, 20 * log10(abs(S.hh) ./ abs(S.vv)));
    end
    shading(shading_mode)
    xlabel('x'); ylabel('y'); zlabel('z');
    caxis([-6 6])
    title('ZDR')
    hc(2) = colorbar('horiz');
    set(hc(2), 'Position', [0.25 0.02 0.5, 0.02])

    if ~verLessThan('matlab', '8.4')
        imfile = sprintf('%s.png', filename(1:end-4));
        im = imread(imfile);
        im = im(end:-1:1, :, :);
        imsize = size(im);
        ha(5) = subplot(2, 3, 4);
        x = linspace(0, 2, imsize(2)) - 1;
        y = linspace(0, 2, imsize(1)) - 1;
        [xx, yy] = meshgrid(x, y);
        zz = zeros(size(xx));
        surf(xx, yy, zz, im)
        shading flat
        xlabel('x'); ylabel('y'); zlabel('z');
        axis([-1 1 -1 1 -1 1])
    end
end

set(ha, 'DataAspect', [1 1 1])
vp.lp = linkprop(ha, {'CameraPosition', 'CameraViewAngle'});
% zoom(1.2)
view(55, 40)
set(gcf, 'UserData', vp);

if exist('blib.m', 'file')
    if style == 1
        %cmap = boonlib('zmap');
        cmap = parula(256);
    else
        cmap = blib('rbmap', 256);
    end
    colormap(ha(1), cmap)
    colormap(ha(2), cmap)
    colormap(ha(3), cmap)
    if style == 2 || style == 3
        blib('bsizewin', gcf, [1200, 900])
        colormap(ha(4), boonlib('rbmap', 256))
    else
        blib('bsizewin', gcf, [800, 450])
    end
end

