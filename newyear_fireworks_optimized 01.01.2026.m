function newyear_fireworks_optimized()
    % Параметры системы
    N_rockets = 4;
    max_sparks_per_rocket = 200;
    g = [0, -9.81, 0];
    dt = 0.025;
    sim_time = 10;
    
    % Цвета
    base_colors = [1 0 0; 0 1 0; 0.5 0.5 1; 1 1 0; 1 0.5 0];
    
    % Инициализация графики
    fig = figure('Color', 'k', 'Position', [100 100 1200 800]);
    ax = axes('Parent', fig, 'Color', 'k');
    hold(ax, 'on');
    axis(ax, 'equal');
    grid(ax, 'on');
    ax.GridColor = [0.3 0.3 0.3];
    ax.GridAlpha = 0.2;
    view(ax, 3);
    
    % Границы сцены
    xlim(ax, [-40 40]);
    ylim(ax, [0 80]);
    zlim(ax, [-30 30]);
    
    % Создание ракет
    rockets = struct('pos', {}, 'vel', {}, 'active', {}, ...
                     'exploded', {}, 'color', {}, 'timer', {});
    
    for i = 1:N_rockets
        rockets(i).pos = [30*rand()-15, 0, 30*rand()-15];
        rockets(i).vel = [4*randn(), 35 + 5*rand(), 4*randn()];
        rockets(i).active = true;
        rockets(i).exploded = false;
        rockets(i).color = base_colors(mod(i-1, size(base_colors,1))+1, :);
        rockets(i).timer = 1 + 1.5*rand();
        rockets(i).spark_count = 0;
    end
    
    % Предварительное выделение памяти для искр
    max_total_sparks = N_rockets * max_sparks_per_rocket;
    spark_pos = zeros(max_total_sparks, 3);
    spark_vel = zeros(max_total_sparks, 3);
    spark_color = zeros(max_total_sparks, 3);
    spark_life = zeros(max_total_sparks, 1);
    spark_size = zeros(max_total_sparks, 1);
    spark_active = false(max_total_sparks, 1);
    
    spark_counter = 0;
    
    % Основной цикл
    frame_count = 0;
    
    for t = 0:dt:sim_time
        % Управление кадрами
        if mod(frame_count, 2) == 0
            cla(ax);
            frame_count = 0;
        end
        frame_count = frame_count + 1;
        
        % Обновление ракет
        for i = 1:N_rockets
            if rockets(i).active
                % Движение ракеты
                k_rocket = 0.08;
                drag = k_rocket * norm(rockets(i).vel) * rockets(i).vel;
                rockets(i).vel = rockets(i).vel + (g - drag) * dt;
                rockets(i).pos = rockets(i).pos + rockets(i).vel * dt;
                rockets(i).timer = rockets(i).timer - dt;
                
                % Взрыв
                if rockets(i).timer <= 0 && ~rockets(i).exploded
                    rockets(i).exploded = true;
                    create_explosion(i);
                end
                
                % Деактивация
                if rockets(i).pos(2) < 0 || t > 8
                    rockets(i).active = false;
                end
            end
        end
        
        % Векторизованное обновление искр
        if spark_counter > 0
            active_idx = find(spark_active(1:spark_counter));
            
            if ~isempty(active_idx)
                % Обновление физики
                k_spark = 0.3;
                
                for idx = active_idx'
                    % Сопротивление воздуха
                    speed = norm(spark_vel(idx, :));
                    drag = k_spark * speed * spark_vel(idx, :);
                    
                    % Интеграция Эйлера
                    spark_vel(idx, :) = spark_vel(idx, :) + (g - drag) * dt;
                    spark_pos(idx, :) = spark_pos(idx, :) + spark_vel(idx, :) * dt;
                    
                    % Уменьшение времени жизни
                    spark_life(idx) = spark_life(idx) - dt;
                    spark_size(idx) = spark_size(idx) * 0.985;
                    
                    % Деактивация
                    if spark_life(idx) <= 0 || spark_pos(idx, 2) < 0
                        spark_active(idx) = false;
                    end
                end
            end
        end
        
        % Визуализация
        visualize_scene();
        
        % Пауза для анимации
        if t < sim_time - dt
            pause(0.01);
        end
    end
    
    % Функция создания взрыва
    function create_explosion(rocket_idx)
        N_sparks = 120 + randi(80);
        center = rockets(rocket_idx).pos;
        base_color = rockets(rocket_idx).color;
        
        for s = 1:N_sparks
            spark_counter = spark_counter + 1;
            
            if spark_counter > max_total_sparks
                break;
            end
            
            % Сферические координаты
            theta = 2*pi*rand();
            phi = acos(2*rand() - 1);
            speed = 15 + 10*rand();
            
            % Преобразование в декартовы
            spark_vel(spark_counter, 1) = speed * sin(phi) * cos(theta);
            spark_vel(spark_counter, 2) = speed * cos(phi);
            spark_vel(spark_counter, 3) = speed * sin(phi) * sin(theta);
            
            % Случайное смещение от центра
            spark_pos(spark_counter, :) = center + 0.5*randn(1,3);
            
            % Цвет с вариациями
            color_var = 0.3*rand(1,3);
            spark_color(spark_counter, :) = max(0, min(1, base_color + color_var));
            
            % Параметры жизни
            spark_life(spark_counter) = 1.5 + rand();
            spark_size(spark_counter) = 3 + 2*rand();
            spark_active(spark_counter) = true;
        end
    end
    
    % Функция визуализации
    function visualize_scene()
        % Рисуем ракеты
        for i = 1:N_rockets
            if rockets(i).active && ~rockets(i).exploded
                plot3(ax, rockets(i).pos(1), rockets(i).pos(2), rockets(i).pos(3), ...
                      'o', 'Color', rockets(i).color, ...
                      'MarkerSize', 6, 'LineWidth', 2);
            end
        end
        
        % Рисуем активные искры
        if spark_counter > 0
            active_idx = find(spark_active(1:spark_counter));
            
            if ~isempty(active_idx)
                % Подготовка данных для scatter3
                x = spark_pos(active_idx, 1);
                y = spark_pos(active_idx, 2);
                z = spark_pos(active_idx, 3);
                sizes = spark_size(active_idx);
                colors = spark_color(active_idx, :);
                
                % Группировка по размеру для оптимизации отрисовки
                [sorted_sizes, sort_idx] = sort(sizes, 'descend');
                x_sorted = x(sort_idx);
                y_sorted = y(sort_idx);
                z_sorted = z(sort_idx);
                colors_sorted = colors(sort_idx, :);
                
                % Отрисовка с разными размерами маркеров
                unique_sizes = unique(round(sorted_sizes*10))/10;
                
                for sz = unique_sizes'
                    mask = abs(sorted_sizes - sz) < 0.1;
                    if any(mask)
                        scatter3(ax, x_sorted(mask), y_sorted(mask), z_sorted(mask), ...
                                sz*15, colors_sorted(mask, :), 'filled', ...
                                'MarkerFaceAlpha', 0.7);
                    end
                end
            end
        end
        
        % Декоративные элементы
        plot3(ax, [-40 40], [0 0], [0 0], 'w-', 'LineWidth', 0.5);
        
        % Обновление заголовка
        title(ax, sprintf('Новогодний салют 2026 | t = %.1f с', t), ...
              'Color', 'w', 'FontSize', 12);
    end
end