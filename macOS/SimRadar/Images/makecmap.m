n = 256;
ii = 1:n;

c = ind2rgb8(ii, jet(n));

c = cat(1, c, ...
    ind2rgb8(ii, hsv(n)));

c = cat(1, c, ...
    ind2rgb8(ii, pink(n)));

c = cat(1, c, ...
    ind2rgb8(ii, cool(n)));

c = cat(1, c, ...
    ind2rgb8(ii, spring(n)));

c = cat(1, c, ...
    ind2rgb8(ii, summer(n)));

c = cat(1, c, ...
    ind2rgb8(ii, autumn(n)));

c = cat(1, c, ...
    ind2rgb8(ii, winter(n)));

c = cat(1, c, ...
    ind2rgb8(ii, gray(n)));

c = cat(1, c, ...
    ind2rgb8(ii, bone(n)));

c = cat(1, c, ...
    ind2rgb8(ii, copper(n)));

c = cat(1, c, ...
    ind2rgb8(ii, circshift(pink(n), [0 2])));

c = cat(1, c, ...
    ind2rgb8(ii, circshift(jet(n), [0 -2])));

% From boonlib
names = {'czmapx', 'carbmap', 'drgmap', 'dgbmap', 'dbrmap', 'ogmap', 'rapmap', 'bjetmapx', 'rainbowmap', 'dmap'};

for k = 1:numel(names)
    m = ind2rgb8(ii, boonlib(names{k}, n));
    c = cat(1, c, m);
    if (k > 1)
        c = cat(1, c, fliplr(m));
    end
end

image(c)
