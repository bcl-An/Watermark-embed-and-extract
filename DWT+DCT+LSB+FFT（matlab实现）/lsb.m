function [watermrkd_img,recmessage,PSNR,NCC,MSSIM,attack_image,attack_message,PSNR_a, NCC_a, MSSIM_a] = lsb(cover_object,message,var)
h=msgbox('Processing');
% blocksize=8;
 message1 =message;
% % determine size of watermarked image
% Mc=size(cover_object,1);    %Height
% Nc=size(cover_object,2);    %Width
% Oc=size(cover_object,3);	%Width 
% max_message=Mc*Nc/(blocksize^2);
% 
% if (length(message) > max_message)
%     error('Message too large to fit in Cover Object')
% end
% 
% Mm=size(message,1);                         %Height
% Nm=size(message,2);                         %Width
% message=round(reshape(message,Mm*Nm,1)./256);
% message_vector=ones(1,max_message);
% % message_vector(1:length(message))=message;
%  message_vector=round(reshape(message,Mm*Nm,1)./256);
% % read in key for PN generator
% file_name='_key.bmp';
% key=double(imread(file_name))./256;
 
% reset MATLAB's PN generator to state "key"
% j = 1;
% for i =1:length(key)
% rand('state',key(i,j));
% end

%%ˮӡ��Ƕ��
%% ��ʼ�� ��ͼƬ
newimg=zeros(512,512,3);

%% ����ͼ��
for rgb = 1:3
    img = cover_object;
    img = img(:,:,rgb); % ѹ��
    img = imresize(img,[512,512]);
    imgsize=size(img);
    %��ȡbitplane����ƽ��
    bitPlane=zeros(imgsize(1),imgsize(2),8);
    for i =1:8
        for ro=1:imgsize(1)% ro: rowͼƬ�кţ�y
            for co=1:imgsize(2) %co: columnͼƬ,x
                bitPlane(ro,co,i)=bitget(img(ro,co), i);
            end
        end
    end
    
    %% ˮӡͼ��
    imgW = message;
    imgW = imresize(imgW,[512,512]);
    imgWsize=size(imgW);
    %��ȡbitplane
    bitPlaneW=zeros(imgWsize(1),imgWsize(2),8);
    for i =1:8
        for ro=1:imgWsize(1)
            for co=1:imgWsize(2)
                bitPlaneW(ro,co,i)=bitget(imgW(ro,co), i);
            end
        end
    end
    
    %% �����µ�bitPlane
    newbitPlane=bitPlane;
    newbitPlane(:,:,3) = bitPlaneW(:,:,8);
    newbitPlane(:,:,2) = bitPlaneW(:,:,7);
    newbitPlane(:,:,1) = bitPlaneW(:,:,6);
    %% ������ͼƬ����ˮӡ�� 
    for i =1:8
        newimg(:,:,rgb)=newimg(:,:,rgb)+newbitPlane(:,:,i)*2^(i-1);
    end
    
end % Ƕ���rgbѭ������

watermarked_image=newimg;
% convert back to uint8
watermarked_image_uint8=uint8(watermarked_image);
watermrkd_img=watermarked_image_uint8;

%% ˮӡ��ȡ����
%��ȡbitplane
for rgb=1:3
    newimg2 = watermrkd_img(:,:,rgb); % ѹ��
    imgW = message;
    imgWsize=size(imgW);
    newimg2 = imresize(newimg2,[imgWsize(1),imgWsize(2)]);
    bitPlaneRec=zeros(imgWsize(1),imgWsize(2),8);
    for i =1:8
        for ro=1:imgWsize(1)
            for co=1:imgWsize(2)
                bitPlaneRec(ro,co,i)=bitget(newimg2(ro,co), i);
            end
        end
    end

    % ��ԭˮӡͼ
    newimgW=zeros(imgWsize(1),imgWsize(2));
    for i =1:3
        newimgW=newimgW+bitPlaneRec(:,:,i)*2^(4+i);
    end
    
end %��ȡ�� rgbѭ������

% read in original watermark
orig_watermark=double(message);
 
% determine size of original watermark
Mo=size(orig_watermark,1);  %Height
No=size(orig_watermark,2);  %Width

message_vector=newimgW;
recmessage=reshape(message_vector,Mo,No);

%% ����
attack_image=attack(watermrkd_img,var);
 %��ȡ�������ˮӡ
for rgb=1:3
    newimg2 = attack_image(:,:,rgb); % ѹ��
    imgW = message;
    imgWsize=size(imgW);
    newimg2 = imresize(newimg2,[imgWsize(1),imgWsize(2)]);
    bitPlaneRec=zeros(imgWsize(1),imgWsize(2),8);
    for i =1:8
        for ro=1:imgWsize(1)
            for co=1:imgWsize(2)
                bitPlaneRec(ro,co,i)=bitget(newimg2(ro,co), i);
            end
        end
    end

    % ��ԭˮӡͼ
    newimgW2=zeros(imgWsize(1),imgWsize(2));
    for i =1:3
        newimgW2=newimgW2+bitPlaneRec(:,:,i)*2^(4+i);
    end
    
end %��ȡ�� rgbѭ������
message_vector2=newimgW2;
attack_message=reshape(message_vector2,Mo,No);

%% calculate the PSNR
I0     = double(cover_object);
I1     = double(watermarked_image_uint8);
Id     = (I0-I1);
signal = sum(sum(I0.^2));
noise  = sum(sum(Id.^2));
MSE  = noise./numel(I0);
peak = max(I0(:));
PSNR = 10*log10(peak^2/MSE(:,:,1));
% PSNR_a
A0=double(watermarked_image_uint8);
A1=double(attack_image);
Ad=(A0-A1);
signal_a = sum(sum(A0.^2));
noise_a  = sum(sum(Ad.^2));
MSE_a  = noise_a./numel(A0);
peak_a = max(A0(:));
PSNR_a = 10*log10(peak_a^2/MSE_a(:,:,1));

%% Normalized Cross Correlation
NCC=ncc(double(message1),recmessage);
% NCC_a
NCC_a=ncc(double(message1),attack_message);

%% calculate the SSIM
MSSIM=ssim(cover_object,watermrkd_img);
% MSSIM_a
MSSIM_a=ssim(watermrkd_img,attack_image);


close(h) 
end
