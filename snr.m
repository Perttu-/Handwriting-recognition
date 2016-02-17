function signr = snr(img)
    ima=max(img);
    imi=min(img);
    ims=std(img);
    signr=20*log10((ima-imi)./ims);
end