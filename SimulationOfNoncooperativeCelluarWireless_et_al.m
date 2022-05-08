clear all;
Ts = 71.4e-6;
deltaf = 15e3;
Tu = 1/deltaf;
Tg = Ts - Tu;
Nsmooth = 14;
Tcoherent = 500e-6;

tao = 3;        %导波个数Npilot
Npilot = tao;
Nslot = 7;      %每个slot的symbols个数
slotEfficiency = (Nslot-Npilot-1)/Nslot;   %1个slot共7个symbols，其中1个是额外的overhead
K = tao*Nsmooth;
B = 20e6;
Nsubcarriers = 1024;
alpha = [1 3 7];
actualB = B./alpha;
gamma = 3.8;        %衰减指数
sigmaShadow = 10^(8/10);
rc = 1600;          %总大小
rh = 100;           %核心区

N_frame=3;     % Number of frames/packet（链路层） 
N_packet=10;   % Number of packets（网络层）；即仿真次数
b=2;            % Number of bits per QPSK symbol
NT=1;  
N_user=K;  
% N_act_user=4; 

N_pbits = N_frame*NT*b; % Number of bits in a packet
N_tbits = N_pbits*N_packet; % Number of total bits

cellCenters = [[-3200, 3200];[0, 3200];[3200, 3200];[-3200, 0];[0, 0];[3200, 0];[-3200, -3200];[0, -3200];[3200, -3200]];
Ncells = length(cellCenters);
scatter(cellCenters(:, 1), cellCenters(:, 2))
title("小区中心点分布")
%%
% 仿真
% qpskmod = comm.QPSKModulator;
qpskmod = comm.QPSKModulator('BitInput',true);
AWGN = comm.AWGNChannel; % 高斯白噪声模块
qpskdemod = comm.QPSKDemodulator('BitOutput',true);

BER = [];
SNRdB = 10;

for M = 1:128
    N_errorbits = 0;
    sigmaNoise = sqrt(NT*0.5*10^(-SNRdB/10));
    rng(0);

    for packet = 1:N_packet
        msg_bit = rand(N_pbits, 1) > 0.5;           %生成 bit
%         msg_bbit = reshape(msg_bit, [N_pbits/b,b]);
%         msg_bbit = msg_bbit(:, 1)*2 + msg_bbit(:, 2);       %b=2, 整理为[0, 3]编码
        %%%%%%%%%%%%%%%发射机%%%%%%%%%%%%%%%%       
        symbol = qpskmod(msg_bit);                      %qpsk调制
        symbol = reshape(symbol, [NT, N_frame]);

        %%信道建模
        H = (randn(Nsubcarriers, M, Ncells, N_user, Ncells) + 1i*randn(Nsubcarriers, M, Ncells, N_user, Ncells))/sqrt(2);        %多径信道
        %beta
        %用户撒点：法1：丢弃法；法2：直接求对应分布
        for j =1:Ncells
            for user = 1:N_user
                ruser = 0;
                while ruser < 100 || ruser > 1600
                    pointx = rand()*3200-1600;
                    pointy = rand()*3200-1600;
                    userpoints(j, user, :) = [pointx pointy];
                    ruser = norm(userpoints(j, user, :));       
                end
                for l = 1:Ncells
                    beta(j, user, l) = lognrnd(0, sigmaShadow)/norm(userpoints(l, user, :)-cellCenters(j, :))^gamma;
                    H(:, :,j, user, l) = H(:, :,j, user, l).*beta(j, user,l);
                end
            end
        end

        


        
        Tx_signal = H*symbol;

        %%%%%%%%%%%%%信道和噪声%%%%%%%%%%%%%%
        noise = sigmaNoise*(randn(N_act_user,N_frame)+j*randn(N_act_user,N_frame));
        interference = 0;
        Rx_signal = Hused*Tx_signal + noise + interference;

        %%%%%%%%%%%%%%%接收机%%%%%%%%%%%%%%%%
        symbol_hat = Rx_signal/beta; % Eq.(12.18)
        symbol_hat = reshape(symbol_hat,NT*N_frame,1);
        bit_hat = qpskdemod(symbol_hat);
        N_errorbits = N_errorbits+sum(msg_bit~=bit_hat);


    end
    BER(end+1) = N_errorbits/N_tbits; 

end

%%
% 画图
semilogy(SNRdBs, BER, '-o');
grid on;
ylim([1e-4, 1])
xlabel("SNR/dB")
ylabel("BER")
%%
%信道容量估算


