## 13.1_modified.m

《MIMO-OFDM无线通信技术及MATLAB实现》一书中程序13.1

单小区（不考虑干扰）、多用户、多发射天线、多径衰落模型，不考虑路径损耗和阴影衰落。

- 对QPSK调制解调使用通信工具箱取代了原来的自写函数

```matlab
qpskmod = comm.QPSKModulator('BitInput',true);
AWGN = comm.AWGNChannel; % 高斯白噪声模块
qpskdemod = comm.QPSKDemodulator('BitOutput',true);

```

- 以固定种子初始化随机数生成器，便于重现
  - 目前更推荐以RNG初始化种子
- 信道、噪声的生成方法
  - 信道只考虑了多径小尺度衰落
  - 信道、噪声都是复数的

```matlab
H(user, :) = (randn(1,NT) + 1i*randn(1,NT))/sqrt(2);        %信道

noise = sigmaNoise*(randn(N_act_user,N_frame)+j*randn(N_act_user,N_frame));	%sigma包含了sqrt(1/2)
interference = 0;
Rx_signal = Hused*Tx_signal + noise + interference;
```

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220508114146282.png" alt="image-20220508114146282" style="zoom: 67%;" />

- 对于其中发射机用到的均衡不太明白





## SimulationOfNoncooperativeCelluarWireless_et_al.m

《Noncooperative Cellular Wireless with Unlimited Numbers of Base Station Antennas》论文仿真代码

- 信道生成更为复杂
  - **不如就用连续14个子载波内的信道？去除下标n**

Denote the complex propagation coefficient between 𝑚-th base station antenna in the 𝑗-th cell, and the 𝑘-th terminal in the ℓ-th cell in the 𝑛-th subcarrier by $𝑔_{𝑛𝑚𝑗𝑘ℓ}$
$$
g_{n m j k \ell}=h_{n m j k \ell} \cdot \beta_{j k \ell}^{1 / 2}
$$

$$
\beta_{j k \ell}=\frac{z_{j k \ell}}{r_{j k \ell}^{\gamma}}
$$

$h_{n m j k \ell}$代表快衰落，$\beta_{j k \ell}$代表几何衰落和阴影衰落。

$N_{\mathrm{smooth}}$个连续子载波内是快衰落$h_{n m j k \ell}$是常数。

```matlab
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
```

- 用户撒点效果

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220512221512161.png" alt="image-20220512221512161" style="zoom:67%;" />



- OFDM调制待完成
- 仿真随着天线数量的增加，噪声消除、误码率变化等情况

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220513105500710.png" alt="image-20220513105500710" style="zoom:50%;" />

- 噪声方差较大时，噪声主导。

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220513105116838.png" alt="image-20220513105116838" style="zoom:50%;" />

- 噪声方差减小，小区间距减小

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220513111503435.png" alt="image-20220513111503435" style="zoom:50%;" />

<img src="C:\Users\71744\AppData\Roaming\Typora\typora-user-images\image-20220513111433631.png" alt="image-20220513111433631" style="zoom: 50%;" />

- 为甚麽需要开个根号？