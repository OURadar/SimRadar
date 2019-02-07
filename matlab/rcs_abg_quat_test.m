% Test if two equivalent quaternions produce same S matrix

eval('common')

% Read in a table
if ~exist('R', 'var')
	R = rcs_view('leaf.rcs', 0);
end

alpha_in = 0.5 * pi;
% beta_in = 1.5 / 180 * pi;
% beta_in = 0.5 / 180 * pi;
beta_in = 0.2;
gamma_in = 0.0;

% Quaternion to be tested
q = r323quat(alpha_in, beta_in, gamma_in);

% Reverse derive alpha, beta, gamma from the quaternion
[alpha, beta, gamma] = quat2abg(q);

% Reconstsruct the quaternion to verify
qr = r323quat(alpha, beta, gamma);

fprintf('Canonical case:\n')
fprintf('abg = [%6.3f %6.3f %6.3f]  q = [%7.4f %7.4f %7.4f %7.4f]   -->  abg'' = [%6.3f %6.3f %6.3f]  q'' = [%7.4f %7.4f %7.4f %7.4f]\n', ...
    alpha_in, beta_in, gamma_in, q, alpha, beta, gamma, qr);

alpha_i = R.alpha_index(alpha);
beta_i = R.beta_index(beta);
cg = cos(gamma);
sg = sin(gamma);
T = [cg, -sg; sg, cg];
Tinv = T.';

hh = read_imagef(R.hh, alpha_i, beta_i);
vv = read_imagef(R.vv, alpha_i, beta_i);
hv = read_imagef(R.hv, alpha_i, beta_i);

Sc = [hh, hv; hv, vv];
S = Tinv * Sc * T



%% Repeat for other cases

q = -q;
[alpha, beta, gamma] = quat2abg(q);
qr = r323quat(alpha, beta, gamma);
fprintf('Negate the quaternion:\n');
fprintf('abg = [%6.3f %6.3f %6.3f]  q = [%7.4f %7.4f %7.4f %7.4f]   -->  abg'' = [%6.3f %6.3f %6.3f]  q'' = [%7.4f %7.4f %7.4f %7.4f]\n', ...
    alpha_in, beta_in, gamma_in, q, alpha, beta, gamma, qr);

alpha_i = R.alpha_index(alpha);
beta_i = R.beta_index(beta);
hh = read_imagef(R.hh, alpha_i, beta_i);
vv = read_imagef(R.vv, alpha_i, beta_i);
hv = read_imagef(R.hv, alpha_i, beta_i);

cg = cos(gamma);
sg = sin(gamma);
T = [cg, -sg; sg, cg];
Tinv = T.';

Sc = [hh, hv; hv, vv];
S = Tinv * Sc * T



% Take some alpha to gamma if beta == 0
if (beta_in > 1 / 180 * pi && beta_in < 179 / 180 * pi)
    return
end

alpha_in = alpha_in + 0.1;
beta_in = 0;
gamma_in = gamma_in - 0.1;
q = r323quat(alpha_in, beta_in, gamma_in);
[alpha, beta, gamma] = quat2abg(q);
qr = r323quat(alpha, beta, gamma);
fprintf('Mixing alpha & gamma:\n');
fprintf('abg = [%6.3f %6.3f %6.3f]  q = [%7.4f %7.4f %7.4f %7.4f]   -->  abg'' = [%6.3f %6.3f %6.3f]  q'' = [%7.4f %7.4f %7.4f %7.4f]\n', ...
    alpha_in, beta_in, gamma_in, q, alpha, beta, gamma, qr);

alpha_i = R.alpha_index(alpha);
beta_i = R.beta_index(beta);
hh = read_imagef(R.hh, alpha_i, beta_i);
vv = read_imagef(R.vv, alpha_i, beta_i);
hv = read_imagef(R.hv, alpha_i, beta_i);

cg = cos(gamma);
sg = sin(gamma);
T = [cg, -sg; sg, cg];
Tinv = T.';

Sc = [hh, hv; hv, vv];
S = Tinv * Sc * T


