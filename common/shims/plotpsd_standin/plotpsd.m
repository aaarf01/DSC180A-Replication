function varargout = plotpsd(y, Fs, varargin)
% Stand-in for CDT's plotpsd, used ONLY when the Signal Processing Toolbox is missing
% (CDT's plotpsd calls periodogram from that toolbox). Computes the same one-sided
% periodogram (rectangular window, default FFT length) with a plain FFT and plots it.
% It affects only the power-spectrum panels of EOF_variance.m, not the EOF results.
y = y(:); n = numel(y);
nfft = max(256, 2^nextpow2(n));
Y = fft(y, nfft);
P = (abs(Y).^2) / (Fs * n);
k = 1:floor(nfft/2) + 1;
P = P(k); P(2:end-1) = 2 * P(2:end-1);
f = (k - 1)' * Fs / nfft;
h = plot(f, P, varargin{:});
if nargout, varargout{1} = h; end      % no output -> nothing printed to the log
end
