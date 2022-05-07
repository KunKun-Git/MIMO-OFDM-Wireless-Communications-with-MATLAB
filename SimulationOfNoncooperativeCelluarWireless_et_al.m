Ts = 71.4e-3;
deltaf = 15e3;
Tu = 1/deltaf;
Tg = Ts - Tu;
Nsmooth = 14;
Tcoherent = 500e-3;

tao = 3;        %导波个数
slotEfficiency = (7-tao-1)/7;   %1个slot共7个symbols，其中1个是额外的overhead
K = tao*Nsmooth;
B = 20e6;
alpha = [1 3 7];
actualB = B./alpha;
gamma = 3.8;        %衰减指数
sigmaShadow = 10^(8/10);
rc = 1600;          %总大小
rh = 100;           %核心区
%%
%信道建模


%%
%信道容量估算