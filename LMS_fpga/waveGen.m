clc;clear;

Fs = 80000;
N = 2^17;
t = 0:1/Fs:N/Fs-1/Fs;

s = 0.3*sin(40*2*pi*t) + 0.2*sin(200*2*pi*t); 
noise = 0.1*randn(1,length(s));
s_add_noise = s + noise;

s_fix = round(s*2^15);
s_add_noise_fix = round(s_add_noise*2^15);

figure(1);
subplot(2,1,1);plot(s_fix);
subplot(2,1,2);plot(s_add_noise_fix);

fid = fopen('s.txt','w');
fid_n = fopen('s_addnoise.txt','w');
for i = 1:N
	fprintf(fid,"%d\n",s_fix(i));
	fprintf(fid_n,"%d\n",s_add_noise_fix(i));
end
fclose(fid);
fclose(fid_n);


