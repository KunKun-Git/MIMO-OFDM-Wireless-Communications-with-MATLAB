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
%K = tao*Nsmooth;
K = 3;
B = 20e6;
Nsubcarriers = 1;
alpha = [1 3 7];
actualB = B./alpha;
gamma = 3.8;        %衰减指数
sigmaShadow = 10^(8/10);
sigmaNoise = 0;
rc = 1600;          %总大小
rh = rc/16;           %核心区

N_frame=3;     % Number of frames/packet（链路层） 
N_packet=10;   % Number of packets（网络层）；即仿真次数
b=2;            % Number of bits per QPSK symbol
NT=1;  
N_user=K;  
% N_act_user=4; 


Mset = 2.^(1:10);

%改成六边形，3层
cellCenters = [[-50*rc, 50*rc];[0, 50*rc];[50*rc, 50*rc];[-50*rc, 0];[0, 0];[50*rc, 0];[-50*rc, -50*rc];[0, -50*rc];[50*rc, -50*rc]];
Ncells = length(cellCenters);
scatter(cellCenters(:, 1), cellCenters(:, 2))
title("小区中心点分布")


N_pbits = Ncells*K*2; % Number of bits in a packet
N_tbits = N_pbits*N_packet; % Number of total bits

%%
% 仿真
% qpskmod = comm.QPSKModulator;
qpskmod = comm.QPSKModulator('BitInput',true);
AWGN = comm.AWGNChannel; % 高斯白噪声模块
qpskdemod = comm.QPSKDemodulator('BitOutput',true);

BER = [];
SNRdB = 10;

for M = Mset
    x = zeros(M, Ncells);
    y = zeros(K, Ncells);
    Ghat = zeros(Ncells, M, K);

    N_errorbits = 0;
%     sigmaNoise = sqrt(NT*0.5*10^(-SNRdB/10));
    sigmaNoise = 0;

%     rng(0);

    for packet = 1:N_packet
        msg_bit = rand(N_pbits, 1) > 0.5;           %生成 bit
%         msg_bbit = reshape(msg_bit, [N_pbits/b,b]);
%         msg_bbit = msg_bbit(:, 1)*2 + msg_bbit(:, 2);       %b=2, 整理为[0, 3]编码
        %%%%%%%%%%%%%%%发射机%%%%%%%%%%%%%%%%       
        columnsymbol = qpskmod(msg_bit);                      %qpsk调制
        symbol = reshape(columnsymbol, [K, Ncells]);

        %%信道建模
        H = (randn(Nsubcarriers, M, Ncells, N_user, Ncells) + 1i*randn(Nsubcarriers, M, Ncells, N_user, Ncells))/sqrt(2);        %多径信道
        %beta
        %用户撒点：法1：丢弃法；法2：直接求对应分布
        for j =1:Ncells
            for user = 1:N_user
                ruser = 0;
                while ruser < rh || ruser > rc
                    pointx = rand()*2*rc-rc;
                    pointy = rand()*2*rc-rc;
                    userpoints(j, user, :) = [pointx pointy];
                    ruser = norm(squeeze(userpoints(j, user, :)));       
                end
                userpoints(j, user, :) = squeeze(userpoints(j, user, :)) +  squeeze(cellCenters(j, :))';
                for l = 1:Ncells
                   % beta(j, user, l) = lognrnd(0, sigmaShadow)/norm(squeeze(userpoints(j, user, :))-squeeze(cellCenters(l, :)))^gamma;
                   beta(l, user, j) = 1/norm(squeeze(userpoints(j, user, :))'-squeeze(cellCenters(l, :)))^gamma;
                   H(:, :,l, user, j) = H(:, :,l, user, j).*beta(l, user, j);
                end
            end
            scatter(userpoints(j, :, 1), userpoints(j, :, 2));
            
            hold on;

        end
        hold off;

        Noise = sigmaNoise * randn(M, Ncells);
        NoiseEstimited = sigmaNoise * randn(M, K, Ncells);

        for j = 1:Ncells
            sumMatrix = zeros(M, 1);
            for l = 1:Ncells
                sumMatrix = sumMatrix + squeeze(H(:, :, j, :, l))*symbol(:, l);
            end
            x(:, j) = sqrt(10.^(SNRdB/10))*sumMatrix + Noise(:, j); 
            sumMatrix = zeros(M, K);
            for l = 1:Ncells
                sumMatrix = sumMatrix + squeeze(H(:, :, j, :, l));
            end
            Ghat = sqrt(10.^(SNRdB/10))*sumMatrix + squeeze(NoiseEstimited(:, :, j));
            y(:, j) = squeeze(Ghat)'*x(:, j);
        end

        bits = qpskdemod(reshape(y, [K*Ncells, 1]));

        N_errorbits = N_errorbits + sum(abs(bits-msg_bit));
        


        
%         Tx_signal = H*symbol;
% 
%         %%%%%%%%%%%%%信道和噪声%%%%%%%%%%%%%%
%         noise = sigmaNoise*(randn(N_act_user,N_frame)+j*randn(N_act_user,N_frame));
%         interference = 0;
%         Rx_signal = Hused*Tx_signal + noise + interference;
% 
%         %%%%%%%%%%%%%%%接收机%%%%%%%%%%%%%%%%
%         symbol_hat = Rx_signal/beta; % Eq.(12.18)
%         symbol_hat = reshape(symbol_hat,NT*N_frame,1);
%         bit_hat = qpskdemod(symbol_hat);
%         N_errorbits = N_errorbits+sum(msg_bit~=bit_hat);


    end
    BER(end+1) = N_errorbits/N_tbits; 

end

%%
% 画图

loglog(Mset, BER, '-o');
grid on;
ylim([1e-4, 1])
xlabel("天线数M")
ylabel("BER")
%%
%信道容量估算


