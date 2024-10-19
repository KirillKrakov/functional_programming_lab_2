defmodule Lab2 do
  @moduledoc """
  Вариант л/р №2 - модуль, в котором используется структура данных AVL-дерево и интерфейс DIct (словарь)
  """
  defmodule Node do
    @moduledoc """
    Узел AVL-дерева. Структура состоит из ключа, значения, высоты дерева, указателей на левое и правое поддеревья
    """
    defstruct [:key, :value, :height, :left, :right]
  end

  defmodule AVLDict do
    @moduledoc """
    Интерфейс - словарь, который использует структуру данных - AVL-дерево
    """
    # Атрибут модуля, обозначающий пустой узел
    @null_node %Node{key: nil, value: nil, left: nil, right: nil, height: 0}

    # Получение высоты наибольшего поддерева с корнем в данном узле
    def height(@null_node), do: 0

    def height(%Node{left: left, right: right}) do
      max(height(left), height(right)) + 1
    end

    # Балансировка узла - когда разница высот левого и правого поддеревьев не равна 2 - возвращаем без изменений
    def balance(
          %Node{left: %Node{height: left_height}, right: %Node{height: right_height}} = node
        )
        when abs(left_height - right_height) <= 1 do
      node
    end

    # Балансировка узла - выполняем правый поворот вокруг узла node
    def balance(
          %Node{
            left:
              %Node{
                left: left_left,
                right: left_right
              } = left,
            right: %Node{height: right_height}
          } = node
        )
        when left_left.height - right_height == 1 do
      new_right_height = max(right_height, left_right.height) + 1

      %Node{
        left
        | height: max(new_right_height, left_right.height) + 1,
          right: %Node{node | height: new_right_height, left: left_right},
          left: left_left
      }
    end

    # Балансировка узла - выполняем левый поворот вокруг узла node
    def balance(
          %Node{
            left: %Node{height: left_height},
            right:
              %Node{
                right: right_right,
                left: right_left
              } = right
          } = node
        )
        when right_right.height - left_height == 1 do
      new_left_height = max(left_height, right_left.height) + 1

      %Node{
        right
        | height: max(new_left_height, right_left.height) + 1,
          left: %Node{node | height: new_left_height, right: right_left},
          right: right_right
      }
    end

    # Балансировка узла - большой правый поворот (сначала левый поворот вокруг left и затем правый вокруг node)
    def balance(
          %Node{
            left:
              %Node{
                right:
                  %Node{left: left_right_left, right: left_right_right} =
                    left_right,
                left: left_left
              } = left,
            right: %Node{height: right_height}
          } = node
        )
        when left_right.height - right_height == 1 do
      %Node{
        left_right
        | height: left_left.height + 2,
          left: %Node{
            left
            | height: left_left.height + 1,
              left: left_left,
              right: left_right_left
          },
          right: %Node{node | height: left_left.height + 1, left: left_right_right}
      }
    end

    # Балансировка узла - большой левый поворот (сначала правый поворот вокруг right и затем левый вокруг node)
    def balance(
          %Node{
            right:
              %Node{
                left:
                  %Node{left: right_left_left, right: right_left_right} =
                    right_left,
                right: right_right
              } = right,
            left: %Node{height: left_height}
          } = node
        )
        when right_left.height - left_height == 1 do
      %Node{
        right_left
        | height: right_right.height + 2,
          left: %Node{node | height: right_right.height + 1, right: right_left_left},
          right: %Node{
            right
            | height: right_right.height + 1,
              left: right_left_right,
              right: right_right
          }
      }
    end

    # Вставка значения узла по ключу в AVL-дерево - если входной узел пустой, то просто
    # создаём новый узел без поддеревьев
    def insert(@null_node, key, value),
      do: %Node{key: key, value: value, height: 1, left: @null_node, right: @null_node}

    # Вставка значения узла по ключу в AVL-дерево - если ключ входного узла совпадает с входным ключом,
    # то обновляем значение во входном узле
    def insert(node, key, value) when node.key == key,
      do: %Node{node | value: value}

    # Вставка значения узла по ключу в AVL-дерево - если ключ входного узла больше входного ключа, то
    #рекурсивно ищем место для значения и вставляем его в левом поддереве. После вставки - балансируем дерево
    def insert(%Node{left: left} = node, key, value) when node.key > key do
      new_left = insert(left, key, value)
      balance(%Node{node | left: new_left, height: max(height(new_left) + 1, node.height)})
    end

    # Вставка значения узла по ключу в AVL-дерево - если ключ входного узла меньше входного ключа, то
    # рекурсивно ищем место для значения и вставляем его в правом поддереве. После вставки - балансируем дерево
    def insert(%Node{right: right} = node, key, value) when node.key < key do
      new_right = insert(right, key, value)
      balance(%Node{node | right: new_right, height: max(height(new_right) + 1, node.height)})
    end

    # Поиск значения узла по ключу в AVL-дереве - если входной узел пустой, то возвращаем атом :not_found
    def find(_key, @null_node), do: :not_found

    # Поиск значения узла по ключу в AVL-дереве - если ключ входного узла совпадает с входным ключом, то
    # возвращаем кортеж из ключа и значения (пару из словаря)
    def find(key, %Node{key: key, value: value}), do: {key, value}

    # Поиск значения узла по ключу в AVL-дереве - если ключ входного узла больше входного ключа, то
    # рекурсивно ищем узел и его значение в левом поддереве
    def find(key, %Node{key: node_key, left: left}) when node_key > key, do: find(key, left)

    # Поиск значения узла по ключу в AVL-дереве - если ключ входного узла меньше входного ключа, то
    # рекурсивно ищем узел и его значение в правом поддереве
    def find(key, %Node{key: node_key, right: right}) when node_key < key, do: find(key, right)

    # функция find_min - возвращает кортеж: {минимальный элемент, новый левый узел, флаг}
    # Поиск узла с минимальным ключём из AVL-дерева для его удаления - когда левое поддерево пусто,
    # узел с минимальным ключом — это текущий узел, удаляем и заменяем его на правое поддерево
    def find_min(%Node{key: key, value: value, height: _, left: @null_node, right: right}) do
      {%Node{key: key, value: value, height: nil, left: nil, right: nil}, right, true}
    end

    # Поиск узла с минимальным ключём из AVL-дерева для его удаления - когда левое поддерево пусто,
    # узел с минимальным ключом находится в левом поддереве
    def find_min(%Node{key: key, value: value, height: _, left: left, right: @null_node}) do
      {left, %Node{key: key, value: value, height: 1, left: @null_node, right: @null_node}, true}
    end

    # Поиск узла с минимальным ключём из AVL-дерева для его удаления - когда оба поддерева не пустые,
    # узел с минимальным ключом находится в левом поддереве, рекурсивно вызываем find_min для left
    def find_min(%Node{
          key: key,
          value: value,
          height: _,
          left: left,
          right:
            %Node{
              left: left_r,
              right: right_r
            } = right
        }) do
      {min, new_left, is_last_call} = find_min(left)

      # Если is_last_call равно true и оба поддерева (новый левый и правый) пусты (высота равна 2), то
      # возвращается узел с минимальным ключом и обновленный узел с высотой 2
      case {is_last_call, %Node{height: height_new_left} = new_left, right_r, right.height} do
        {true, @null_node, @null_node, 2} ->
          {min,
           %Node{
             left_r
             | height: 2,
               left: %Node{
                 key: key,
                 value: value,
                 height: 1,
                 left: @null_node,
                 right: @null_node
               },
               right: %Node{
                 key: right.key,
                 value: right.value,
                 height: 1,
                 left: @null_node,
                 right: @null_node
               }
           }, false}

        # Если is_last_call равно true, но только левое поддерево пусто, то возвращается узел с минимальным ключом
        # и обновленный узел с правым поддеревом
        {true, @null_node, _, _} ->
          {min,
           %Node{
             key: right.key,
             value: right.value,
             height: max(left_r.height + 1, right_r.height) + 1,
             left: %Node{
               key: key,
               value: value,
               left: @null_node,
               right: left_r,
               height: left_r.height + 1
             },
             right: right_r
           }, false}

        # В ином случае возвращается узел с минимальным ключом и сбалансированный узел с обновленной высотой
        _ ->
          {min,
           balance(%Node{
             key: key,
             value: value,
             height: max(height_new_left + 1, right.height) + 1,
             left: new_left,
             right: right
           }), false}
      end
    end

    # Функция remove возвращает дерево AVLDict (а точнее корневой узел дерева Node) после удаления элемента
    # Удаление узлов из AVL-дерева - если дерево пустое, то ключ не найден, возвращается атом :not_found
    def remove(_key, @null_node), do: :not_found

    # Удаление узлов из AVL-дерева - если узел с указанным ключом найден и не имеет ни левого, ни правого поддеревьев,
    # то узел просто удаляется, и возвращается @null_node
    def remove(key, %Node{
          key: key,
          value: _value,
          height: _,
          left: @null_node,
          right: @null_node
        }),
        do: @null_node

    # Удаление узлов из AVL-дерева - если узел с указанным ключом найден и имеет только левое поддерево, то
    # левое поддерево возвращается как новое значение узла
    def remove(key, %Node{key: key, value: _value, height: _, left: left, right: @null_node}),
      do: left

    # Удаление узлов из AVL-дерева - если узел с указанным ключом найден и имеет только правое поддерево, то
    # правое поддерево возвращается как новое значение узла
    def remove(key, %Node{key: key, value: _value, height: _, left: @null_node, right: right}),
      do: right

    # Удаление узлов из AVL-дерева - если узел с указанным ключом найден и имеет оба поддерева, то используется
    # узел с минимальным ключом из правого поддерева (полученный через find_min)
    def remove(key, %Node{
          key: key,
          value: _value,
          height: _,
          left: left,
          right: right
        }) do
      {min, new_right, _} = find_min(right)

      case min do
        # Если узел с минимальным ключом пустой, то возвращается пустой узел
        @null_node ->
          @null_node

        # В ином случае создаётся новый узел, равный по ключу и значению полученному узлу из правого поддерева,
        # определяется его высота и выполняется балансировка получившегося дерева
        %Node{key: min_key, value: min_value} ->
          balance(%Node{
            key: min_key,
            value: min_value,
            left: left,
            right: new_right,
            height: max(left.height, new_right.height) + 1
          })
      end
    end

    # Удаление узлов из AVL-дерева - если указанный ключ меньше ключа текущего узла, то
    # рекурсивно вызывается remove для левого поддерева, находится новое левое поддерево
    def remove(target_key, %Node{
          key: key,
          value: value,
          height: _,
          left: left,
          right: right
        })
        when target_key < key do
      new_left = remove(target_key, left)

      case {new_left, right} do
        # Если новое левое поддерево не найдено, то возвращается атом :not_found
        {:not_found, _} ->
          :not_found

        # Если новое левое поддерево и правое поддерево пусты, то создается новый узел
        {@null_node, @null_node} ->
          %Node{key: key, value: value, height: 1, left: @null_node, right: @null_node}

        # В противном случае выполняется балансировка для дерева, состоящего из нового левого и правого поддеревьев
        {%Node{height: height_new_left}, _} ->
          balance(%Node{
            key: key,
            value: value,
            height: max(height_new_left, right.height) + 1,
            left: new_left,
            right: right
          })
      end
    end

    # Удаление узлов из AVL-дерева - если указанный ключ больше ключа текущего узла, то
    # рекурсивно вызывается remove для правого поддерева, находится новое правое поддерево
    def remove(target_key, %Node{
          key: key,
          value: value,
          height: _,
          left: left,
          right: right
        })
        when target_key > key do
      new_right = remove(target_key, right)

      case {left, new_right} do
        # Если новое правое поддерево не найдено, то возвращается атом :not_found
        {_, :not_found} ->
          :not_found

        # Если новое правое поддерево и левое поддерево пусты, то создается новый узел
        {@null_node, @null_node} ->
          %Node{key: key, value: value, height: 1, left: @null_node, right: @null_node}

        # В противном случае выполняется балансировка для дерева, состоящего из левого и нового правого поддеревьев
        {_, %Node{height: height_new_right}} ->
          balance(%Node{
            key: key,
            value: value,
            height: max(height_new_right, left.height) + 1,
            left: left,
            right: new_right
          })
      end
    end

    # Функция wrap_remove является обёрткой для вызова remove, проверяющей результат удаления.
    def wrap_remove(key, tree) do
      case remove(key, tree) do
        # Если результат — :not_found, то возвращает исходное дерево
        :not_found -> tree
        # Если результат — кортеж (с новым деревом), то возвращает новое дерево
        {_, new_tree, _} -> new_tree
        # В ином случае возвращает новое дерево
        new_tree -> new_tree
      end
    end

    # Преобразование дерева в список пар - если дерево пустое, то возвращается пустой список
    def to_list(@null_node), do: []

    # Преобразование дерева в список пар - функция обрабатывает левое поддерево, затем добавляет текущий узел
    # (ключ и значение) и, наконец, обрабатывает правое поддерево. Результат рекурсивного преобразования AVL-дерева
    # в список пар {key, value} - список всех узлов дерева в порядке обхода
    def to_list(%Node{key: key, value: value, left: left, right: right}) do
      to_list(left) ++ [{key, value}] ++ to_list(right)
    end

    # Cоздание AVL-дерева из списка пар {key, value} - используется функция foldl для обхода списка и вставки каждого
    # элемента в дерево с помощью функции insert. Начальное значение для аккумулятора — пустой узел
    def from_list(list) do
      :lists.foldl(fn {key, value}, acc -> insert(acc, key, value) end, @null_node, list)
    end

    # Применение (map) заданной функции func к каждому узлу дерева - если входной узел пустой (дерево пустое),
    # то возвращается пустой список
    def map(nil, _), do: []

    # Применение (map) заданной функции func к каждому узлу дерева - если дерево не пустое,
    # то map рекурсивно обходит левое поддерево, применяет функцию func к текущему узлу и затем обходит правое
    # поддерево. В итоге возвращается список результатов применения функции ко всем узлам.
    def map(%Node{key: key, value: value, left: left, right: right}, func) do
      map(left, func) ++ [func.({key, value})] ++ map(right, func)
    end

    # Отображение (map) функции func к каждому узлу дерева с возвращением нового дерева с измененными значениями.
    def map_tree(node, func) do
      from_list(map(node, func))
    end

    # Левая свёртка дерева - если входной узел пустой (дерево пустое), то возвращается аккумулятор без изменений.
    def foldl(@null_node, acc, _), do: acc

    # Левая свёртка дерева - если дерево не пустое, то сначала функция foldl обходит левое поддерево (foldl(left,..))
    # и применяет функцию func к аккумулятору и текущему узлу (func.(foldl(...),{...}), затем она обходит правое
    # поддерево (foldl(right,..)). В результате получается итоговое значение после применения функции ко всем узлам.
    def foldl(%Node{key: key, value: value, left: left, right: right}, acc, func) do
      foldl(right, func.(foldl(left, acc, func), {key, value}), func)
    end

    # Правая свёртка дерева - если входной узел пустой (дерево пустое), то возвращается аккумулятор без изменений.
    def foldr(@null_node, acc, _), do: acc

    # Правая свёртка дерева - если дерево не пустое, то сначала функция foldr обходит правое поддерево (foldl(right,..))
    # и применяет функцию func к аккумулятору и текущему узлу (func.(foldr(...),{...}), затем она обходит левое
    # поддерево (foldr(left,..)). В результате получается итоговое значение после применения функции ко всем узлам.
    def foldr(%Node{key: key, value: value, left: left, right: right}, acc, func) do
      foldr(left, func.(foldr(right, acc, func), {key, value}), func)
    end

    # Фильтрация узлов дерева на основе заданной функции func - если входной узел пустой (дерево пустое),
    # то возвращается пустой список
    def filter(@null_node, _), do: []

    # Фильтрация узлов дерева на основе заданной функции func - если дерево не пустое, то
    # вызывается заданная функция func для текущего узла
    def filter(%Node{key: key, value: value, height: _, left: left, right: right}, func) do
      case func.(key, value) do
        # Если функция возвращает true, узел добавляется в результат
        true ->
          filter(left, func) ++ [{key, value}] ++ filter(right, func)

        # Если функция возвращает false, узел пропускается
        false ->
          filter(left, func) ++ filter(right, func)

          # Результат — список всех узлов, удовлетворяющих условию, в порядке обхода
      end
    end

    # Фильтрация узлов дерева на основе заданной функции func c возвращением нового дерева,
    # содержащего только удовлетворяющие условиям функции узлы
    def filter_tree(tree, func), do: from_list(filter(tree, func))

    # Объединение 2 AVL-деревьев x и y - используется функция foldl, чтобы пройти по всем узлам дерева y
    # и вставить каждый узел в дерево x с помощью функции insert
    # Результат — новое дерево, содержащее все узлы из обоих деревьев
    def merge(x, y) do
      foldl(y, x, fn acc, {key, value} -> insert(acc, key, value) end)
    end

    # Проверка равенства 2 AVL-деревьев x и у - сначала вычисляется и сравнивается количество узлов каждого дерева.
    # Если длины деревьев не равны, то функция сразу возвращает false. Если длины равны, она проходит по всем узлам
    # дерева y и проверяет, содержится ли каждый узел с тем же ключом и значением в дереве x. Если все узлы совпадают,
    # функция возвращает true, иначе — false.
    def equal_tree(x, y) do
      lenx = foldl(x, 0, fn acc, _ -> acc + 1 end)
      leny = foldl(y, 0, fn acc, _ -> acc + 1 end)

      case lenx == leny do
        false -> false
        _ -> foldl(y, true, fn acc, {key, value} -> acc and find(key, x) === {key, value} end)
      end
    end
  end
end
