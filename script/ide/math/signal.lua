--[[
Title: signal (TODO not implemented yet)
Author(s): LiXizhi
Desc: like fast fourier transform, wavelet transform, etc.
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/signal.lua");
local signal = commonlib.gettable("mathlib.signal");
-------------------------------------------------------
]]

local signal = commonlib.gettable("mathlib.signal");


-- Fast Fourier transform
-- @param x: input array
function signal.fft(x)
	local N = #x;
	if (N <= 1) then
		return x;
	end
	local even = {};
	local odd = {};
	for i = 1, N, 2 do
		even[#even + 1] = x[i];
		odd[#odd + 1] = x[i + 1];
	end
	even = signal.fft(even);
	odd = signal.fft(odd);
	local T = {};
	local halfN = math.floor(N / 2)
	for k = 1, halfN do
		local t = math.exp(-2 * math.pi * (k - 1) / N) * odd[k];
		T[k] = even[k] + t;
		T[k + halfN] = even[k] - t;
	end
	return T;
end

-- create a signal window
-- @param window_type: "hann", "hamming", "blackman", "bartlett", "rectangular". default to "hann"
function signal.window(window_type, window_size)
	local window = {};
	if (not window_type or window_type == "hann") then
		for i = 1, window_size do
			window[i] = 0.5 * (1 - math.cos(2 * math.pi * (i - 1) / (window_size - 1)));
		end
	elseif (window_type == "hamming") then
		for i = 1, window_size do
			window[i] = 0.54 - 0.46 * math.cos(2 * math.pi * (i - 1) / (window_size - 1));
		end
	elseif (window_type == "blackman") then
		for i = 1, window_size do
			window[i] = 0.42 - 0.5 * math.cos(2 * math.pi * (i - 1) / (window_size - 1)) + 0.08 * math.cos(4 * math.pi * (i - 1) / (window_size - 1));
		end
	elseif (window_type == "bartlett") then
		for i = 1, window_size do
			window[i] = 2 / (window_size - 1) * ((window_size - 1) / 2 - math.abs((i - 1) - (window_size - 1) / 2));
		end
	elseif (window_type == "rectangular") then
		for i = 1, window_size do
			window[i] = 1;
		end
	end
	return window;
end

-- Computes the Short-time Fourier Transform of signals.
function signal.stft(x, window_size, hop_size, window_type)
	local window = signal.window(window_type, window_size);
	local N = #x;
	local M = math.floor((N - window_size) / hop_size + 1);
	local X = {};
	for m = 1, M do
		local start = (m - 1) * hop_size + 1;
		local stop = start + window_size - 1;
		local frame = {};
		for i = start, stop do
			frame[#frame + 1] = x[i] * window[i - start + 1];
		end
		frame = signal.fft(frame);
		X[m] = frame;
	end
	return X;
end
