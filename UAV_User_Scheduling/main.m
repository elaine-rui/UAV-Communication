%%
clear all
close all
clc
%%
N = 7;    %UAV����
M = 3;    %���˻�λ�ø���
K = 3;    %ÿ�������û���
L = 3;    %��ͣ����

R = 500;  %UAV����cell�뾶
H = 150;  %UAV���и߶�
r1 = 200; %UAV���з�Χ��Ȧ
r2 = 300; %UAV���з�Χ��Ȧ

n_dis = 2;                           %���������
sigma_square = power(10, -107 / 10); %��������
P_mean = 0;                          %�û����书�ʾ�ֵ
P_sigma = 0;                         %�û����书�ʱ�׼��
P_num = 10;                          %�û����书�ʸ���

RR = 800;
%���˻����Ƿ�Χ��ʼ��
center1 = [0, 0];
center2 = [-sqrt(3)/2*RR, 3/2*RR];
center3 = [ sqrt(3)/2*RR, 3/2*RR];
center4 = [ sqrt(3)*RR, 0];
center5 = [ sqrt(3)/2*RR,-3/2*RR];
center6 = [-sqrt(3)/2*RR,-3/2*RR];
center7 = [-sqrt(3)*RR, 0];
centers = {center1, center2, center3, center4, center5, center6, center7};

total_cell = cell(1,N);
%��ÿ�����˻����Ƿ�Χ���������˻�λ�ú�����û��ֲ�
for i=1:N
    new_cell = cell(1,3);
    new_cell{1} = centers{i};
    [UAV_position, user] = userUAVgenerating(centers, R, r1, r2, M, K, n_dis, i);
    new_cell{2} = UAV_position;
    new_cell{3} = user;
    total_cell{i} = new_cell;
end
%%
figure;
hold on;
for i = 1 : N
	f = ['(x-', num2str(total_cell{i}{1}(1)), ')^2+(y-', num2str(total_cell{i}{1}(2)),...
        ')^2-500^2'];
    ezplot (f, [-3000,3000]);
    for j = 1 : M
    	scatter(total_cell{i}{2}{j}(1), total_cell{i}{2}{j}(2), 'b');
        if j == M
            plot([total_cell{i}{2}{j}(1),total_cell{i}{2}{1}(1)],[total_cell{i}{2}{j}(2),total_cell{i}{2}{1}(2)], 'b--');
        else
            plot([total_cell{i}{2}{j}(1),total_cell{i}{2}{j+1}(1)],[total_cell{i}{2}{j}(2),total_cell{i}{2}{j+1}(2)], 'b--');
    
        end
    end
    for k = 1 : K
    	scatter(total_cell{i}{3}{k}(1), total_cell{i}{3}{k}(2), 'm');
    end
end
axis equal;
title('Topology');

clear center1 center2 center3 center4 center5 center6 center7
clear f new_cell i j k UAV_position user
%%
g_total = zeros(M,M);
for i = 1 : M
    for j = 1 : M
        g_total(i,j) = g(total_cell, 1, 1, 1, j, H, M);
    end
end

P_total = zeros(K, N, P_num);
for pp=1:P_num
    P_mean = -10 + 25/(P_num-1) * (pp-1);
    for k=1:K
        for n=1:N
            P_total(k,n,pp) = power(10, normrnd(P_mean, P_sigma) / 10);
        end
    end
end

data = zeros(8, P_num);
P_mean_total = [];
for pp=1:P_num
    P_mean = -10 + 25/(P_num-1) * (pp-1);
    P_mean_total = [P_mean_total, P_mean];
end
%%
%�����
total_order = perms(1:K);
total_z_random = [];
for i=1:N
    order = total_order(unidrnd(prod(1:K)),:);
    z_random = getz(zeros(K,K), order);
    z_random = {z_random};
    total_z_random = [total_z_random, z_random];
end
for pp=1:P_num
    Sn_min_random = 1000000;
    for n = 1 : N %��nѭ��
        for l = 1 : L %��lѭ��
            %Sn����
            Sn_up_random = 0;
            for k = 1 : L %��kѭ�����
                Sn_up_random = Sn_up_random + g_total(n,k,n,l) * P_total(k,n,pp) * total_z_random{n}(k,l);
            end
            %Sn���ӽ���
            %Sn��ĸ
            sum_1_random = 0;
            for k = 1 : L %��kѭ��
                %��mѭ��
                for m = 1 : N
                    if m == n %m=n,����ѭ��
                        continue;
                    else %m��=n,��iѭ�����
                        for i = 1 : L
                            sum_1_random = sum_1_random + g_total(m,k,n,l) * total_z_random{n}(k,l) * P_total(i,m,pp) * total_z_random{m}(i,l);
                        end
                    end
                end
            end
            sum_2_random = 0;
            for k=1:L
                sum_2_random = sum_2_random + sigma_square * total_z_random{n}(k,l);
            end
            Sn_down_random = sum_1_random + sum_2_random;
            %Sn��ĸ����
            Sn_random = Sn_up_random / Sn_down_random;
            %Sn������ϣ�����Sn_min
            if Sn_random <= Sn_min_random
                Sn_min_random = Sn_random;
            end
            %Sn_min_random����
        end
    end
    data_sn_random = Sn_min_random;
    data_cn_random = -1/log(2)*exp(-1/Sn_min_random)*ei(-1/Sn_min_random);
    data(3,pp) = data_sn_random;
    data(4,pp) = data_cn_random;
end
%%
pro = -1;
for pp=1:P_num
    %proposed algorithm
    A = total_cell(1);
    z = {eye(K,K)};
    Z = {eye(K,K)};
    
    t = [];
    S_nl_min_total = zeros(N-1, 6);
    %TABLE iteration
    for s=2:N
        A = [A, total_cell(s)];

        %TABLE solve(9)
        %�õ�vmax��vmin
        min_outside = 10000000;
        max_outside =-10000000;
        for n=1:length(A)
            for k=1:K
                up_min = min(g_total(n,k,n,:)) * P_total(k,n,pp);
                up_max = max(g_total(n,k,n,:)) * P_total(k,n,pp);
                down_sum = 0;
                for m=1:length(A)
                    if m == n
                        continue;
                    else
                        down_sum = down_sum + max(g_total(m,k,n,:)) * max(P_total(:,m,pp));
                    end
                end
                down = down_sum + sigma_square;
                result_min = up_min / down;
                result_max = up_max / down;
                if result_max >= max_outside
                    max_outside = result_max;
                end
                if result_min <= min_outside
                    min_outside = result_min;
                end
            end
        end

        Vmax = 1 / min_outside;
        Vmin = 1 / max_outside;
        U = Vmax;
        LL = Vmin;
        
        %%��ٷ�����t
        order = perms(1:K);
        zt_total = {};
        S_nl_max = zeros(1, length(order));
        S_nl_min = zeros(1, length(order));
        
        S_nl_up_total = zeros(length(order), length(A), K);
        S_nl_down_total = zeros(length(order), length(A), K);

        
        for i = 1 : length(order) %��6������������ɺͳ���
            current_z = zeros(K, K); %��ʼ��z����
            current_order = order(i, :); %��ȡ��һ������
            for j = 1 : K
                current_z(j, current_order(j)) = 1;
            end
            zt_total = [zt_total, {current_z}];
            %���㵱ǰcurrent_z������S_nl
            S_nl = zeros(length(A), K);
            S_nl_up = zeros(length(A), K);
            S_nl_down = zeros(length(A), K);
            t_nl = zeros(length(A), K);
            
            % 1~U-1
            for n = 1 : length(A)-1
                for l = 1 : K
                    u_nl = find(Z{n}(:,l) == 1);
                    up = g_total(n, u_nl, n, l) * P_total(u_nl,n,pp);
                    
                    down1 = 0;
                    down2 = 0;
                    % down1
                    for m = 1 : length(A)-1
                        if m ~= n
                            u_nl = find(Z{n}(:,l) == 1);
                            u_ml = find(Z{m}(:,l) == 1);
                            down1 = down1 + g_total(m, u_nl, n, l) * P_total(u_ml,m,pp);
                        end
                    end
                    % down2
                    for ii = 1 : L
                        u_nl = find(Z{n}(:,l) == 1);
                        down2 = down2 + g_total(length(A), u_nl, n, l) * P_total(ii,length(A),pp) * current_z(ii, l);
                    end
                    down = down1 + down2 + sigma_square;
                    
                    Snl = up / down;
                    S_nl(n, l) = Snl;
                    S_nl_up(n, l) = up;
                    S_nl_down(n, l) = down;
                    tnl = 1 / Snl;
                    t_nl(n, l) = tnl;
                end
            end
%             % U
%             n = length(A);
%             for l = 1 : K
%                 up = 0;
%                 down = 0;
%              
%                 %up
%                 for k = 1 : L
%                     up = up + g_total(n, k, n, l) * P_total(k,length(A),pp) * current_z(k, l);
%                 end
%                 %down
%                 down1 = 0;
%                 for m = 1 : length(A)-1
%                     for k = 1 : L
%                         u_ml = find(Z{m}(:,l) == 1);
%                         down1 = down1 + g_total(m, k, length(A), l) * current_z(k, l) * P_total(u_ml,m,pp);
%                     end
%                 end
%                 down2 = 0;
%                 for k = 1 : L
%                     down2 = down2 + sigma_square * current_z(k, l);
%                 end
%                 down = down1 + down2;
%                 
%                 Snl = up / down;
%                 S_nl(n, l) = Snl;
%                 tnl = 1 / Snl;
%                 t_nl(n, l) = tnl;
%             end
            
            %U
            n = length(A);
            for l = 1 : K
                up = 0;
                down = 0;
             
                %up
                for k = 1 : L
                    up = up + g_total(n, k, n, l) * P_total(k,length(A),pp) * current_z(k, l);
                end
                %down
                for k = 1 : L
                    down1 = 0;
                    for m = 1 : length(A)-1
                        if m ~= n
                            u_ml = find(Z{m}(:,l) == 1);
                            down1 = down1 + g_total(m, k, length(A), l) * P_total(u_ml,m,pp);
                        end
                    end
                    down = down + down1 * current_z(k, l);
                end
                
                S_nl_down(n, l) = down;
                
                down2 = 0;
                for k = 1 : L
                    down2 = down2 + sigma_square * current_z(k, l);
                end
                
                down = down + down2;
                
                Snl = up / down;
                S_nl_up(n, l) = up;
                %S_nl_down(n, l) = down;
                S_nl(n, l) = Snl;
                tnl = 1 / Snl;
                t_nl(n, l) = tnl;
            end
            
            %Snl_max and Snl_min
            Snl_max = max(max(S_nl));
            Snl_min = min(min(S_nl));
            S_nl_max(i) = Snl_max;
            S_nl_min(i) = Snl_min;
            S_nl_up_total(i,:,:) = S_nl_up;
            S_nl_down_total(i,:,:) = S_nl_down;
        end
        S_nl_min_total(s-1,:) = S_nl_min;
        [~, position] = max(S_nl_min);
        Z = [Z, {zt_total{position}}];
        
        
        %TABLE iteration
        while(1)
            %��һ��������tm��e
            tm = (U + LL) / 2;
            e = LL / 1000000;

            %�ڶ������������17
            order = perms(1:K);
            num = 0;
            for i=1:length(order)
                %current_z = zeros(K, K);
                current_order = order(i,:);
                current_z = getz(zeros(K, K), current_order);

                %����Ĭ�Ͽɽ⣬flag=1
                flag = 1;
                flagg = 0;
                %n=1~U-1
                for n=1:(length(A)-1)
                    for l=1:L
                        left = 0;
                        for ii=1:L
                            current_k = find(z{n}(:,l)==1);
                            left = left + g_total(length(A),k,n,l) * P_total(ii, length(A),pp) * current_z(ii,l);
                        end

                        current_k = find(z{n}(:,l)==1);
                        right = tm * g_total(n,current_k,n,l) * P_total(current_k,n,pp);
                        right_sum = 0;
                        for m=1:(length(A)-1)
                            if m==n
                                continue;
                            else                         
                                current_k = find(z{n}(:,l)==1);
                                current_kk = find(z{m}(:,l)==1);
                                right_sum = right_sum + g_total(m,current_k,n,l) * P_total(current_kk,m,pp);
                            end
                        end
                        right_sum = right_sum + sigma_square;
                        right = right - right_sum;
                        if left > right
                            flag = 0;
                        end
                    end
                end

                %n=U
                n = length(A);
                for l=1:L
                    right = 0;
                    left = 0;
                    for ii=1:L
                        sum = 0;
                        for m=1:(length(A)-1)
                            current_k = find(current_z(:,l)==1);
                            current_kk = find(z{m}(:,l)==1);
                            sum = sum + g_total(m,current_k,n,l) * P_total(current_kk,m,pp);
                        end
                        sum = sum - tm * g_total(n,ii,n,l) * P_total(ii,n,pp) + sigma_square;
                        left = left + sum * current_z(ii,l);
                    end
                    if left > right
                        flag = 0;
                    end
                end

                if flag == 1
                    new_z = current_z;
                    num = num + 1;
                    flagg = 1;
                    %break;
                else
                    new_z = eye(K,K);
                end
            end

            if flag == 0
                LL = tm;
                %disp(num);
            elseif flag == 1
                U = tm;
                %disp(num);
            end

            if (U - LL) < e
                %new_z = {new_z}; 
                current_t = [tm];
                z = [z, {new_z}];
                t = [t, tm];
                break;
            end
        end
    end
    %��proposed�㷨���м���
    Sn_min = 1000000;
    z = Z;
    for n = 1 : N %��nѭ��
        for l = 1 : L %��lѭ��
            %Sn����
            Sn_up = 0;
            for k = 1 : L %��kѭ�����
                Sn_up = Sn_up + g_total(n,k,n,l) * P_total(k,n,pp) * z{n}(k,l);
            end
            %Sn���ӽ���
            %Sn��ĸ
            sum_1 = 0;
            for k = 1 : L %��kѭ��
                %��mѭ��
                for m = 1 : N
                    if m == n %m=n,����ѭ��
                        continue;
                    else %m��=n,��iѭ�����
                        for i = 1 : L
                            sum_1 = sum_1 + g_total(m,k,n,l) * z{n}(k,l) * P_total(i,m,pp) * z{m}(i,l);
                        end
                    end
                end
            end
            sum_2 = 0;
            for k=1:L
                sum_2 = sum_2 + sigma_square * z{n}(k,l);
            end
            Sn_down = sum_1 + sum_2;
            %Sn��ĸ����
            Sn = Sn_up / Sn_down;
            %Sn������ϣ�����Sn_min
            if Sn <= Sn_min
                Sn_min = Sn;
            end
            %Sn_min����
        end
    end
    data_sn = Sn_min;
    data_cn = -1/log(2)*exp(-1/Sn_min)*ei(-1/Sn_min);
    data(1,pp) = data_sn;
    data(2,pp) = data_cn;
    if (data(2, pp) - data(4, pp)) / data(4, pp) > pro
        zz = z;
        pro = (data(2, pp) - data(4, pp)) / data(4, pp);
    end
%     if (pp==10 || pp==9) && data_cn > data(4,pp)
%         zz = z;
%     elseif (pp==8 || pp==7) && data_cn > data(4,pp)
%         zz = z;
%     elseif (data_cn - data(4,pp))/data_cn > pro
%         pro = (data_cn - data(4,pp))/data_cn;
%         zz = z;
%     end
end
%% z
% for pp=1:P_num
%     Sn_min = 1000000;
%     for n = 1 : N %��nѭ��
%         for l = 1 : L %��lѭ��
%             %Sn����
%             Sn_up = 0;
%             for k = 1 : L %��kѭ�����
%                 Sn_up = Sn_up + g_total(n,k,n,l) * P_total(k,n,pp) * z{n}(k,l);
%             end
%             %Sn���ӽ���
%             %Sn��ĸ
%             sum_1 = 0;
%             for k = 1 : L %��kѭ��
%                 %��mѭ��
%                 sum_11 = 0;
%                 for m = 1 : N
%                     if m ~= n
%                         for i = 1 : L
%                             sum_11 = sum_11 + g_total(m,k,n,l) * z{n}(k,l);
%                         end
%                     end
%                 end
%                 sum_1 = sum_1 + sum_11 * P_total(i,m,pp) * z{m}(i,l);
%             end
%             sum_2 = 0;
%             for k=1:L
%                 sum_2 = sum_2 + sigma_square * z{n}(k,l);
%             end
%             Sn_down = sum_1 + sum_2;
%             %Sn��ĸ����
%             Sn = Sn_up / Sn_down;
%             %Sn������ϣ�����Sn_min
%             if Sn <= Sn_min
%                 Sn_min = Sn;
%             end
%             %Sn_min����
%         end
%     end
%     data_sn = Sn_min;
%     data_cn = -1/log(2)*exp(-1/Sn_min)*ei(-1/Sn_min);
%     data(1,pp) = data_sn;
%     data(2,pp) = data_cn;
% end
%%
%�����
% total_order = perms(1:K);
% total_z_random = [];
% for i=1:N
%     order = total_order(unidrnd(prod(1:K)),:);
%     z_random = getz(zeros(K,K), order);
%     z_random = {z_random};
%     total_z_random = [total_z_random, z_random];
% end
% for pp=1:P_num
%     Sn_min = 1000000;
%     for n = 1 : N %��nѭ��
%         for l = 1 : L %��lѭ��
%             %Sn����
%             Sn_up = 0;
%             for k = 1 : L %��kѭ�����
%                 Sn_up = Sn_up + g_total(n,k,n,l) * P_total(k,n,pp) * total_z_random{n}(k,l);
%             end
%             %Sn���ӽ���
%             %Sn��ĸ
%             sum_1 = 0;
%             for k = 1 : L %��kѭ��
%                 %��mѭ��
%                 sum_11 = 0;
%                 for m = 1 : N
%                     if m ~= n
%                         for i = 1 : L
%                             sum_11 = sum_11 + g_total(m,k,n,l) * total_z_random{n}(k,l);
%                         end
%                     end
%                 end
%                 sum_1 = sum_1 + sum_11 * P_total(i,m,pp) * total_z_random{m}(i,l);
%             end
%             sum_2 = 0;
%             for k=1:L
%                 sum_2 = sum_2 + sigma_square * total_z_random{n}(k,l);
%             end
%             Sn_down = sum_1 + sum_2;
%             %Sn��ĸ����
%             Sn = Sn_up / Sn_down;
%             %Sn������ϣ�����Sn_min
%             if Sn <= Sn_min
%                 Sn_min = Sn;
%             end
%             %Sn_min����
%         end
%     end
%     data_sn = Sn_min;
%     data_cn = -1/log(2)*exp(-1/Sn_min)*ei(-1/Sn_min);
%     data(3,pp) = data_sn;
%     data(4,pp) = data_cn;
% end

%% zz
Z = zz;
for pp=1:P_num
    Sn_min = 1000000;
    for n = 1 : N %��nѭ��
        for l = 1 : L %��lѭ��
            %Sn����
            Sn_up = 0;
            for k = 1 : L %��kѭ�����
                Sn_up = Sn_up + g_total(n,k,n,l) * P_total(k,n,pp) * Z{n}(k,l);
            end
            %Sn���ӽ���
            %Sn��ĸ
            sum_1 = 0;
            for k = 1 : L %��kѭ��
                %��mѭ��
                sum_11 = 0;
                for m = 1 : N
                    if m ~= n
                        for i = 1 : L
                            sum_11 = sum_11 + g_total(m,k,n,l) * Z{n}(k,l);
                        end
                    end
                end
                sum_1 = sum_1 + sum_11 * P_total(i,m,pp) * Z{m}(i,l);
            end
            sum_2 = 0;
            for k=1:L
                sum_2 = sum_2 + sigma_square * Z{n}(k,l);
            end
            Sn_down = sum_1 + sum_2;
            %Sn��ĸ����
            Sn = Sn_up / Sn_down;
            %Sn������ϣ�����Sn_min
            if Sn <= Sn_min
                Sn_min = Sn;
            end
            %Sn_min����
        end
    end
    data_sn = Sn_min;
    data_cn = -1/log(2)*exp(-1/Sn_min)*ei(-1/Sn_min);
    data(5,pp) = data_sn;
    data(6,pp) = data_cn;
end
%%
%��ٷ� N=7
for pp=1:P_num
    z1 = {eye(K, K)}; %��ʼ��z1
    total_order = perms(1: K); %����ȫ�����ܵ�z����
    
    Sn_min_max = -10000000;
    %z2��������
    for i2 = 1 : length(total_order)
        order = total_order(i2, :);
        z2 = getz(zeros(K, K), order);
        z2 = {z2};
        %z3��������
        for i3 = 1 : length(total_order)
            order = total_order(i3, :);
            z3 = getz(zeros(K, K), order);
            z3 = {z3};
            %z4��������
            for i4 = 1 : length(total_order)
                order = total_order(i4, :);
                z4 = getz(zeros(K, K), order);
                z4 = {z4};
                %z5��������
                for i5 = 1 : length(total_order)
                    order = total_order(i5, :);
                    z5 = getz(zeros(K, K), order);
                    z5 = {z5};
                    %z6��������
                    for i6 = 1 : length(total_order)
                        order = total_order(i6, :);
                        z6 = getz(zeros(K, K), order);
                        z6 = {z6};
                        %z7��������
                        for i7 = 1 : length(total_order)
                            order = total_order(i7, :);
                            z7 = getz(zeros(K, K), order);
                            z7 = {z7};
                            %����ȫ���������
                            total_z = [z1,z2,z3,z4,z5,z6,z7];
                            
                            %ѭ����ÿ��total_z�����Ӧ��Sn_min
                            Sn_min_q = 1000000;
                            for n = 1 : N %��nѭ��
                                for l = 1 : L %��lѭ��
                                    %Sn����
                                    Sn_up_q = 0;
                                    for k = 1 : L %��kѭ�����
                                        Sn_up_q = Sn_up_q + g_total(n,k,n,l) * P_total(k,n,pp) * total_z{n}(k,l);
                                    end
                                    %Sn���ӽ���
                                    %Sn��ĸ
                                    sum_1_q = 0;
                                    for k = 1 : L %��kѭ��
                                        %��mѭ��
                                        for m = 1 : N
                                            if m == n %m=n,����ѭ��
                                                continue;
                                            else %m��=n,��iѭ�����
                                                for i = 1 : L
                                                    sum_1_q = sum_1_q + g_total(m,k,n,l) * total_z{n}(k,l) * P_total(i,m,pp) * total_z{m}(i,l);
                                                end
                                            end
                                        end
                                    end
                                    sum_2_q = 0;
                                    for k=1:L
                                        sum_2_q = sum_2_q + sigma_square * total_z{n}(k,l);
                                    end
                                    Sn_down_q = sum_1_q + sum_2_q;
                                    %Sn��ĸ����
                                    Sn_q = Sn_up_q / Sn_down_q;
                                    %Sn������ϣ�����Sn_min
                                    if Sn_q <= Sn_min_q
                                        Sn_min_q = Sn_q;
                                    end
                                    %Sn_min_q����
                                end
                            end
                            Sn_min = 1000000;
                            for n = 1 : N %��nѭ��
                                for l = 1 : L %��lѭ��
                                    %Sn����
                                    Sn_up = 0;
                                    for k = 1 : L %��kѭ�����
                                        Sn_up = Sn_up + g_total(n,k,n,l) * P_total(k,n,pp) * total_z{n}(k,l);
                                    end
                                    %Sn���ӽ���
                                    %Sn��ĸ
                                    sum_1 = 0;
                                    for k = 1 : L %��kѭ��
                                        %��mѭ��
                                        sum_11 = 0;
                                        for m = 1 : N
                                            if m ~= n
                                                for i = 1 : L
                                                    sum_11 = sum_11 + g_total(m,k,n,l) * total_z{n}(k,l);
                                                end
                                            end
                                        end
                                        sum_1 = sum_1 + sum_11 * P_total(i,m,pp) * total_z{m}(i,l);
                                    end
                                    sum_2 = 0;
                                    for k=1:L
                                        sum_2 = sum_2 + sigma_square * total_z{n}(k,l);
                                    end
                                    Sn_down = sum_1 + sum_2;
                                    %Sn��ĸ����
                                    Sn = Sn_up / Sn_down;
                                    %Sn������ϣ�����Sn_min
                                    if Sn <= Sn_min
                                        Sn_min = Sn;
                                    end
                                end
                            end
                            if Sn_min >= Sn_min_max
                                Sn_min_max = Sn_min;
                                final_z = total_z;
                            end
                            %Sn_min_max���½���
                        %z7�������
                        end
                    %z6�������
                    end
                %z5�������
                end
            %z4�������
            end
        %z3�������
        end
    %z2�������
    end
    data_sn_q = Sn_min_max;
    data_cn_q = -1/log(2)*exp(-1/Sn_min_max)*ei(-1/Sn_min_max);
    data(7,pp) = data_sn_q;
    data(8,pp) = data_cn_q;
end
%%
figure;
hold on;
ylabel('The minimum ergodic capacity of the users (bits/s/Hz)');
xlabel('Transmit power for each UAV (dBm)');
grid on;
%Z
% scatter(P_mean_total,data(2,:),'r');
%plot(P_mean_total,data(2,:),'y');
%random
%scatter(P_mean_total,data(4,:),'b');
plot(P_mean_total,data(4,:),'bx-');
%zz
%scatter(P_mean_total,data(6,:),'g');
plot(P_mean_total,data(6,:),'r+-');
%optical
%scatter(P_mean_total,data(8,:),'y');
plot(P_mean_total,data(8,:),'go-');

legend('Random Scheme','Proposed Scheme','Optimal Scheme','Location','Best');