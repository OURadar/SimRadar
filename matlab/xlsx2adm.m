a = 0:5:180;
b = -180:5:180;
[bi, ai] = meshgrid(b, a);
adm = zeros(numel(b), numel(a), 6);

% filename = '/Users/boonleng/Downloads/Cube_Wind_force_coefficient_and_moment_coefficient.xlsx';
filename = '/Users/boonleng/Downloads/Plate_Wind_force_coefficient_and_moment_coefficient.xlsx';

for t = 1:6
    [num, txt, raw] = xlsread(filename, t + 1, 'A2:F24');

    %r
    beta = num(:, 1);
    alpha_txt = raw(1, 2:end);
    alpha = zeros(1, length(alpha_txt));
    for ii = 1:length(alpha_txt)
        a = sscanf(alpha_txt{ii}(3:end-3), '%f', 1);
        fprintf('%s -> %.2f\n', alpha_txt{ii}, a);
        alpha(ii) = a;
    end

    [b, a] = meshgrid(beta, alpha);
    values = num(:, 2:end).';

    %% Check the dimensions
    if length(alpha) ~= size(values, 1)
        fprintf('Inconsistent number of rows (alpha @ %d vs values @ %d).\n', length(alpha), size(values, 2));
        return
    end
    
    if length(beta) ~= size(values, 2)
        fprintf('Inconsistent number of columns (beta @ %d vs values @ %d).\n', length(beta), size(values, 1));
        return
    end

    % Interpolated coordinates
    vv = griddata(b, a, values, bi, ai);
    oo = vv;

    % Duplicate patches
    bi_s = find(bi(1, :) == 0);
    bi_e = find(bi(1, :) == 90);
    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 45);
    template = vv(ai_s:ai_e, bi_s:bi_e);

    bi_s = find(bi(1, :) == 90);
    bi_e = find(bi(1, :) == 180);
    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 45);
    vv(ai_s:ai_e, bi_s:bi_e) = -fliplr(template);

    bi_s = find(bi(1, :) == 0);
    bi_e = find(bi(1, :) == 180);
    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 45);
    template = vv(ai_s:ai_e, bi_s:bi_e);

    bi_s = find(bi(1, :) == -180);
    bi_e = find(bi(1, :) == 0);
    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 45);
    if t == 1 || t == 4
        vv(ai_s:ai_e, bi_s:bi_e) = fliplr(template);
    else
        vv(ai_s:ai_e, bi_s:bi_e) = -fliplr(template);
    end

    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 45);
    template = vv(ai_s:ai_e, :);

    ai_s = find(ai(:, 1) == 45);
    ai_e = find(ai(:, 1) == 90);
    vv(ai_s:ai_e, :) = flipud(template);

    ai_s = find(ai(:, 1) == 0);
    ai_e = find(ai(:, 1) == 90);
    template = vv(ai_s:ai_e, :);

    ai_s = find(ai(:, 1) == 90);
    ai_e = find(ai(:, 1) == 180);
    if t == 3 || t == 6
        vv(ai_s:ai_e, :) = -flipud(template);
    else
        vv(ai_s:ai_e, :) = flipud(template);
    end
    
    adm(:, :, t) = vv.';
    %%
    
    if t > 1
        continue
    end
    
    figure(1)
    ha = subplot(3, 1, 1);
    imagesc(beta, alpha, values.')
    cc = caxis;
    clim = max(abs(cc)) * [-1 1];
    caxis(clim)

    ha(2) = subplot(3, 1, 2);
    imagesc(bi(1, :), ai(:, 1), oo)
    caxis(clim)

    ha(3) = subplot(3, 1, 3);
    imagesc(bi(1, :), ai(:, 1), vv)
    caxis(clim)
    xlabel('Beta')
    ylabel('Alpha')

    colorbar('h')

    set(ha, 'YDir', 'Normal')
end

% lp = linkprop(ha, {'CLim'});

%%
figure(2)
clf
k = [1, 3, 5, 2, 4, 6];
tt = {'dx', 'dy', 'dz', 'mx', 'my', 'mz'};
for ii = 1:6
    subplot(3, 2, k(ii))
    imagesc(bi(1, :), ai(:, 1), adm(:, :, ii).')
    if ii <= 3
        caxis([-1.5, 1.5])
    else
        caxis([-0.25, 0.25])
    end
    hold on
    plot([0, 90, 90, 0, 0], [0, 0, 45, 45, 0], 'g', 'LineWidth', 2)
    hold off
    colorbar
    xlabel('Beta (deg)')
    ylabel('Alpha (deg)')
    title(tt{ii}, 'FontWeight', 'Bold', 'FontSize', 12)
    set(gca, 'YDir', 'Normal')
end

%%
fid = fopen('test.adm', 'w');
fwrite(fid, size(vv, 2), 'uint16');
fwrite(fid, size(vv, 1), 'uint16');
fwrite(fid, adm(:), 'float');
fclose(fid);
