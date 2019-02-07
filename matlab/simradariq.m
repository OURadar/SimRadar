% SimRadar IQ Reader
%
% dat = simradariq(filename) returns a structure that contains the raw I/Q
% data produced by the radar simulator.
%
% Boon Leng Cheong
% Advanced Radar Research Center
% University of Oklahoma
% 2016/02/09

function dat = simradariq(filename)

if ~exist('filename', 'var')
    error('I need at least a filename.\n')
end

dat = struct('filenam', filename, 'params', [], 'debris_counts', [], 'iqh', [], 'iqv', [], 'az_deg', [], 'el_deg', [], 'scan_time', []);

fid = fopen(filename, 'r');
if (fid < 0 )
    error('Error opening file')
end

tmpf = fread(fid, 24, 'float');
tmpi = fread(fid, 1, 'uint');
debris_counts = fread(fid, 8, 'uint');
scan_mode = fread(fid, 16, 'char=>char');
scan_mode = deblank(scan_mode.');
tmpf2 = fread(fid, 3, 'float');
tmpi2 = fread(fid, 1, 'uint');

hdr = struct(...
    'c', tmpf(1), ...
    'prt', tmpf(2), ...
    'loss', tmpf(3), ...
    'lambda', tmpf(4), ...
    'tx_power_watt', tmpf(5), ...
    'antenna_gain_dbi', tmpf(6), ...
    'antenna_bw_deg', tmpf(7), ...
    'tau', tmpf(8), ...
    'range_start', tmpf(9), ...
    'range_end', tmpf(10), ...
    'range_delta', tmpf(11), ...
    'azimuth_start', tmpf(12), ...
    'azimuth_end', tmpf(13), ...
    'azimuth_delta', tmpf(14), ...
    'elevation_start', tmpf(15), ...
    'elevation_end', tmpf(16), ...
    'elevation_delta', tmpf(17), ...
    'domain_pad_factor', tmpf(18), ...
    'body_per_cell', tmpf(19), ...
    'prf', tmpf(20), ...
    'va', tmpf(21), ...
    'fn', tmpf(22), ...
    'antenna_bw_rad', tmpf(23), ...
    'dr', tmpf(24), ...
    'range_count', tmpi(1), ...
    'scan_mode', scan_mode, ...
    'scan_start', tmpf2(1), ...
    'scan_end', tmpf2(2), ...
    'scan_delta', tmpf2(3), ...
    'seed', tmpi2(1));

% Move to the end of file
fseek(fid, 0, 'eof');
fsize = ftell(fid);

% The I/Q data portion
payload_size = fsize - 1024;
pulse_size = 32 + hdr.range_count * 16;
pulse_count = payload_size / pulse_size;
fprintf('Data file contains %d pulses. D = %.2f\n', pulse_count, hdr.body_per_cell);

% Return to the end of file header
fseek(fid, 1024, 'bof');

dat.params = hdr;
dat.debris_counts = debris_counts;
dat.scan_time = zeros(1, pulse_count);
dat.az_deg = zeros(1, pulse_count);
dat.el_deg = zeros(1, pulse_count);
dat.iqh = zeros(hdr.range_count, pulse_count, 'single');
dat.iqv = zeros(hdr.range_count, pulse_count, 'single');

for ii = 1 : pulse_count
    pulse_origin = ftell(fid);
    phdr = fread(fid, 3, 'float');
    % ignore the rest since pulse_header has 32 bytes
    fseek(fid, pulse_origin + 32, 'bof');
    
    dat.scan_time(ii) = phdr(1);
    dat.el_deg(ii) = phdr(2);
    dat.az_deg(ii) = phdr(3);
    
    tmpf = fread(fid, hdr.range_count * 4, 'float=>float');
    dat.iqh(:, ii) = tmpf(1 : 4 : end) + 1i * tmpf(2 : 4 : end);
    dat.iqv(:, ii) = tmpf(3 : 4 : end) + 1i * tmpf(4 : 4 : end);
end

fclose(fid);
