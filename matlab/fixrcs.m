% Correct the X-band files

% files = {'Plywood_X_304.rcs', 'Plywood_X_609.rcs', 'Plywood_X_914.rcs', 'Plywood_X_1219.rcs'};
files = {'2by4_X_304.rcs', '2by4_X_609.rcs', '2by4_X_1219.rcs', '2by4_X_2438.rcs'};

for ii = 1:numel(files)
    % filename = strcat('/Users/boonleng/Downloads/Plywood/', files{ii});
    filename = strcat('/Users/boonleng/Downloads/2by4/', files{ii});
    fprintf('%s\n', filename)
    fid = fopen(filename, 'r');
    if (fid < 0)
        error('Unable to open file');
    end

    alpha_count = fread(fid, 1, 'uint16');
    beta_count = fread(fid, 1, 'uint16');
    alpha_count = 901;
    beta_count = 451;
    table = fread(fid, 'float');
    fclose(fid);

    filename = strcat('/Users/boonleng/Downloads/rcs/', files{ii});
    fprintf('--> %s\n', filename)
    fid = fopen(filename, 'w');
    fwrite(fid, alpha_count, 'uint16');
    fwrite(fid, beta_count, 'uint16');
    fwrite(fid, table, 'float');
    fclose(fid);
end
