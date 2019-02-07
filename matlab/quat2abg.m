function [alpha, beta, gamma] = quat2abg(q)

beta_arg = q(4) * q(4) + q(3) * q(3) - q(2) * q(2) - q(1) * q(1);

% Lump everything to gamma when beta ~ 0.0f deg or 180.0 deg (< 1.0 deg or > 179.0 deg);
if (beta_arg > 0.999847 || beta_arg < -0.999847)
    alpha = 0;
    beta = 0;
    gamma = sign(q(3)) * acos(q(4)) * 2;
else
	gamma = atan2(q(2) * q(3) + q(4) * q(1) , q(4) * q(2) - q(1) * q(3));
	beta  =  acos(q(4) * q(4) + q(3) * q(3) - q(2) * q(2) - q(1) * q(1));
	alpha = atan2(q(2) * q(3) - q(4) * q(1) , q(1) * q(3) + q(4) * q(2));
end
