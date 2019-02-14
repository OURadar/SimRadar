% RCS files to ball view in PNG 

% folder = '/Users/boonleng/Downloads/2by4/';
folder = '/Users/boonleng/Downloads/Plywood/';
filenames = dir([folder, '*.rcs']);
filenames = {filenames.name}.';

for ii = 5:numel(filenames)
    filename = filenames{ii};
    fullpath = [folder, filename];
    rcs_view(fullpath)
    print('-dpng', '-r144', [fullpath, '.png'])
end
