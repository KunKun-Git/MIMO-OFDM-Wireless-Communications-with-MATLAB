clear all;
Ts = 71.4e-3;
deltaf = 15e3;
Tu = 1/deltaf;
Tg = Ts - Tu;
Nsmooth = 14;
Tcoherent = 500e-3;

tao = 3;        %导波个数Npilot
Npilot = tao;
Nslot = 7;      %每个slot的symbols个数
slotEfficiency = (Nslot-Npilot-1)/Nslot;   %1个slot共7个symbols，其中1个是额外的overhead
K = tao*Nsmooth;
B = 20e6;
alpha = [1 3 7];
actualB = B./alpha;
gamma = 3.8;        %衰减指数
sigmaShadow = 10^(8/10);
rc = 1600;          %总大小
rh = 100;           %核心区

N_frame=10;     % Number of frames/packet（链路层） 
N_packet=200;   % Number of packets（网络层）
b=2;            % Number of bits per QPSK symbol
NT=4;  
N_user=20;  
N_act_user=4; 
I=eye(N_act_user,NT);
N_pbits = N_frame*NT*b; % Number of bits in a packet
N_tbits = N_pbits*N_packet; % Number of total bits
SNRdBs = [0:2:20];

%%
%信道建模
% qpskmod = comm.QPSKModulator;
qpskmod = comm.QPSKModulator('BitInput',true);
AWGN = comm.AWGNChannel; % 高斯白噪声模块
qpskdemod = comm.QPSKDemodulator('BitOutput',true);

BER = [];
for SNRdB = SNRdBs
    N_errorbits = 0;
    sigmaNoise = sqrt(NT*0.5*10^(-SNRdB/10));
    rand('seed', 1);
    randn('seed', 1);

    for packet = 1:N_packet
        msg_bit = rand(N_pbits, 1) > 0.5;           %生成 bit
%         msg_bbit = reshape(msg_bit, [N_pbits/b,b]);
%         msg_bbit = msg_bbit(:, 1)*2 + msg_bbit(:, 2);       %b=2, 整理为[0, 3]编码
        %%%%%%%%%%%%%%%发射机%%%%%%%%%%%%%%%%       
        symbol = qpskmod(msg_bit);                      %qpsk调制
        symbol = reshape(symbol, [NT, N_frame]);
        for user = 1:N_user
            H(user, :) = (randn(1,NT) + 1i*randn(1,NT))/sqrt(2);        %信道
            channelNorm(user) = norm(H(user, :));
        end
        [chNorm, Index] = sort(channelNorm, 'descend');
        Hused = H(Index(1:N_act_user), :);  %按范数排序
        temp_W = Hused'*inv(Hused*Hused');
        beta = sqrt(NT/trace(temp_W*temp_W'));   
        W = beta*temp_W;
        Tx_signal = W*symbol;               %已知CSI的预均衡(12.17),(12.19)

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
semilogy(SNRdBs, BER, '-o');
grid on;
ylim([1e-4, 1])
xlabel("SNR/dB")
ylabel("BER")
%%
%信道容量估算

