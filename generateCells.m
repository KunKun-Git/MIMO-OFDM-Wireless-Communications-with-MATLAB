function CELL = generateCells(bsNum, r)

    % bsNum=19;
    % r=16;    %覆盖半径
     
    % x=solve('3*(n-1)*n=yy','n');
    s = roots([3, -3, 1-bsNum]);
    n=ceil(max(s(1),s(2)))+1;
     
    N_col = n;   %列
    % 列数设置
    N_row = 4*n;   %行  *2
     
    % 生成六边形中点坐标 %
    CELL0=[];
    y_point= 0;
    for i_row =1:1:N_row
        
        if(mod(i_row,2)==1)   %第一列 第i_row行的x坐标
            x_point =r;
        else
            x_point = 2.5*r;
        end
        y_point= y_point+ sqrt(3)/2*r;     %第一列 第i_row行的y坐标
        
        for i_col = 1:1:N_col    %第i_col列的x&y坐标
            x_point = x_point+ 3*r;
            CELL0(i_row,i_col)=x_point;
            CELL0(i_row+N_row,i_col)=y_point;
        end
     
    end
    centerpoint=[CELL0(ceil(N_row/2),ceil(N_col/2)),CELL0(ceil(N_row/2)+N_row,ceil(N_col/2))];
     
     
    CEx=reshape(CELL0(1:N_row,:),N_row*N_col,1)-centerpoint(1,1);
    CEy=reshape(CELL0(N_row+1:2*N_row,:),N_row*N_col,1)-centerpoint(1,2);
    CELL0=[CEx,CEy];
     
    CELL0(:,3)=sqrt(CELL0(:,1).^2+CELL0(:,2).^2); 
    CELL=sortrows(CELL0,3);
     
    CELL(bsNum+1:N_row*N_col,:)=[];
    CELL(:,3)=[];
    for i=1:size(CELL,1)
       scatter(CELL(i,2),CELL(i,1),'filled','b');
       axis equal;
       hold on;
        
    end
    scatter(0,0,'filled','r')

end