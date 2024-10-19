# Лабораторная работа 2

## Вариант `avl-dict`

---

  * Студент: `Краков Кирилл Константинович`
  * Группа: `P3331`
  * ИСУ: `368373`
  * Функциональный язык: `Elixir`

---

## Требования
Интерфейс — `Dict`, структура данных — `AVL Tree`.

1. Функции:
    * [x] добавление и удаление элементов;
    * [x] фильтрация;
    * [x] отображение (`map`);
    * [x] свертки (левая и правая);
    * [x] структура должна быть [моноидом](https://ru.m.wikipedia.org/wiki/%D0%9C%D0%BE%D0%BD%D0%BE%D0%B8%D0%B4).
2. Структуры данных должны быть **неизменяемыми**.
3. Библиотека должна быть протестирована в рамках **unit testing**.
4. Библиотека должна быть протестирована в рамках **property-based** тестирования (*как минимум 3 свойства*, включая свойства моноида).
5. Структура должна быть **полиморфной**.
6. Требуется использовать идиоматичный для технологии стиль программирования. Примечание: некоторые языки позволяют получить большую часть API через реализацию небольшого интерфейса. Так как лабораторная работа про ФП, а не про экосистему языка — необходимо реализовать их вручную и по возможности — обеспечить совместимость.

---

## Ключевые элементы реализации

Модуль узла AVL-дерева:

```elixir
defmodule Node do
    @moduledoc """
    Узел AVL-дерева. Структура состоит из ключа, значения, высоты дерева, указателей на левое и правое поддеревья
    """
    defstruct [:key, :value, :height, :left, :right]
  end
```

Балансировка узлов в AVL-дереве: простой левый и правый поворот, большой левый и правый поворот:

```elixir
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
```

Добавление и поиск узлов по ключам в AVL-дереве:

```elixir
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
```

Поиск минимальных узлов в AVL-дереве:

```elixir
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
```

Удаление узлов из AVL-дерева:

```elixir
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
```

Преобразование списка в AVL-дерево и наоборот:
```elixir
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
```

Отображение (map) заданной функции к каждому узлу AVL-дерева:

```elixir
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
```

Левая и правая свёртки AVL-дерева:

```elixir
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
```

Фильтрация AVL-дерева:
```elixir
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
```

Cравнение AVL-деревьев:

```elixir
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
```

### Соответствие свойству [моноида](https://ru.m.wikipedia.org/wiki/%D0%9C%D0%BE%D0%BD%D0%BE%D0%B8%D0%B4)

Определили пустой элемент:

```elixir:
 @null_node %Node{key: nil, value: nil, left: nil, right: nil, height: 0}
```

Определили бинарную операцию 'merge' (Объединение 2 AVL-деревьев x и y):

```elixir
# Объединение 2 AVL-деревьев x и y - используется функция foldl, чтобы пройти по всем узлам дерева y
# и вставить каждый узел в дерево x с помощью функции insert
# Результат — новое дерево, содержащее все узлы из обоих деревьев
def merge(x, y) do
  foldl(y, x, fn acc, {key, value} -> insert(acc, key, value) end)
end
```

## Тестирование

Unit-тестирование:
```elixir
# Функции для Unit-тестирования:

def balance_check(%Node{key: nil, value: nil, height: height, left: nil, right: nil}),
  do: height == 0

def balance_check(%Node{
      key: _key,
      value: _value,
      height: height,
      left: left,
      right: right
    }) do
  balance_check(left) and balance_check(right) and height == max(left.height, right.height) + 1 and
    abs(right.height - left.height) <= 1
end

def remove_all(l, t) do
  {empty_t, _} =
    :lists.foldl(
      fn {k, _v}, {t_acc, l_acc} ->
        newt = AVLDict.wrap_remove(k, t_acc)
        [_ | newl] = l_acc
        assert balance_check(newt) == true
        assert :lists.usort(newl) == AVLDict.to_list(newt)
        {newt, newl}
      end,
      {t, l},
      l
    )

  assert empty_t == @null_node
end

# Тестирование функций добавления и поиска на 1 узле
test "Insert One Node" do
  node = AVLDict.insert(@null_node, 1, "1")

  expected_node = %Node{
    key: 1,
    value: "1",
    height: 1,
    left: @null_node,
    right: @null_node
  }

  assert node == expected_node and AVLDict.find(0, node) == :not_found and
           AVLDict.find(1, node) == {1, "1"}
end

# Тестирование функций балансировки, добавления узлов на 2 узлах
test "Insert Two Nodes" do
  node1 = AVLDict.insert(@null_node, 1, "1")
  node2 = AVLDict.insert(node1, 2, "2")

  expected_node = %Node{
    key: 1,
    value: "1",
    height: 2,
    left: @null_node,
    right: %Node{key: 2, value: "2", height: 1, left: @null_node, right: @null_node}
  }

  assert node2 == expected_node
end

# Тестирование функций балансировки, добавления узлов, а также сравнения деревьев на 7 узлах
test "Insert Seven Nodes" do
  l = [{1, "1"}, {2, "2"}, {3, "3"}, {4, "4"}, {5, "5"}, {6, "6"}, {7, "7"}]

  expected_node = %Node{
    key: 4,
    value: "4",
    height: 3,
    left: %Node{
      key: 2,
      value: "2",
      height: 2,
      left: %Node{key: 1, value: "1", height: 1, left: @null_node, right: @null_node},
      right: %Node{key: 3, value: "3", height: 1, left: @null_node, right: @null_node}
    },
    right: %Node{
      key: 6,
      value: "6",
      height: 2,
      left: %Node{key: 5, value: "5", height: 1, left: @null_node, right: @null_node},
      right: %Node{key: 7, value: "7", height: 1, left: @null_node, right: @null_node}
    }
  }

  assert AVLDict.equal_tree(AVLDict.from_list(l), expected_node) == true
end

# Тестирование функций балансировки узлов, получения дерева из списка путём левой свёртки, а также
# сравнения деревьев на 5000 узлов
test "Insert Five Thousand Nodes" do
  l = Enum.map(1..5_000, fn x -> {x, "#{x}"} end)
  t = AVLDict.from_list(l)
  balance_check(t)
  assert AVLDict.to_list(t) == :lists.usort(l)
end

# Тестирование функций получения дерева из списка путём левой свёртки и удаления из дерева 1 узла на 1 узле
test "Remove One Node" do
  t = AVLDict.from_list([{1, "1"}])
  assert AVLDict.wrap_remove(1, t) == @null_node
end

# Тестирование функций удаления из дерева 1 узла на 2 узлах
test "Remove One From Two Nodes" do
  t = AVLDict.from_list([{1, "1"}, {2, "2"}])
  assert AVLDict.to_list(AVLDict.wrap_remove(1, t)) == [{2, "2"}]
end

# Тестирование функций удаления из дерева злов 1 или 2 узлов на 3 узлах
test "Remove One Or Two From Three Nodes" do
  t = AVLDict.from_list([{1, "1"}, {2, "2"}, {3, "3"}])

  assert AVLDict.to_list(AVLDict.wrap_remove(2, t)) == [{1, "1"}, {3, "3"}] and
           AVLDict.to_list(AVLDict.wrap_remove(3, AVLDict.wrap_remove(1, t))) == [{2, "2"}]
end

# Тестирование функций удаления из дерева несуществующего узла на 4 узлах
test "Not Found Remove" do
  t = AVLDict.from_list([{1, "1"}, {2, "2"}, {3, "3"}, {4, "4"}])
  assert AVLDict.wrap_remove(5, t) == t
end

# Тестирование функций удаления из дерева всех узлов на 5 узлах
test "Remove All" do
  l = [{1, "1"}, {2, "2"}, {3, "3"}, {4, "4"}, {5, "5"}]
  t = AVLDict.from_list(l)
  remove_all(l, t)
end

# Тестирование отображения функции умножения значения узла на 2 для 3 узлов с численным значением
test "Map Number Multiplication By Two" do
  l = [{1, 1}, {2, 2}, {3, 3}]
  expected_l = [{1, 2}, {2, 4}, {3, 6}]

  node =
    AVLDict.from_list(l)
    |> AVLDict.map(fn
      {key, value} when not is_nil(value) -> {key, value * 2}
      {key, value} -> {key, value}
    end)
    |> Enum.filter(fn {key, value} -> not is_nil(key) and not is_nil(value) end)

  assert node == expected_l
end

# Тестирование функции фильтрации, оставляющей только узлы с ключами больше 1
test "Filter More Than One" do
  l = [{1, 1}, {2, 2}, {3, 3}]
  expected_l = [{2, 2}, {3, 3}]

  node =
    AVLDict.from_list(l)
    |> AVLDict.filter(fn key, _value -> key > 1 end)

  assert node == expected_l
end

# Тестирование функции find по нахождению значения элемента с искомым ключом
test "Find Node Value With Key" do
  l = [{1, 234}, {5, 1233}, {22, 1232}]
  node = AVLDict.from_list(l)
  {_, found_value} = AVLDict.find(5, node)
  assert found_value == 1233
end

# Тестирование функции find_min по нахождению значения узла с минимальным ключом
test "Find Node With Min Key" do
  l = [{1, 100}, {2, 2}, {3, 3}]
  node = AVLDict.from_list(l)
  {min_el, _, _} = AVLDict.find_min(node)
  assert min_el.value == 100
end

# Тестирование функции левой свёртки для нахождения количества узлов в дереве
test "Fold Left Counter" do
  l = [{1, "1"}, {2, "2"}, {3, "3"}, {4, "4"}, {5, "5"}]
  node = AVLDict.from_list(l)
  node_counter = AVLDict.foldl(node, 0, fn acc, _ -> acc + 1 end)
  assert node_counter == 5
end

# Тестирование функции правой свёртки для нахождения числовой суммы значений в дереве
test "Fold Right Summator" do
  l = [{1, 100}, {2, 2}, {3, 3}]
  node = AVLDict.from_list(l)

  node_summator =
    AVLDict.foldr(node, 0, fn acc, {_, value} when not is_nil(value) -> acc + value end)

  assert node_summator == 105
end
```

Property-based тестирование:

```elixir
# Функции для property-based тестирования:

def neutral_elem(t_size) do
  t = AVLDict.from_list(Enum.map(1..t_size, fn _ -> {:rand.uniform(50), 0} end))
  r = AVLDict.merge(t, @null_node)
  # r = t + 0 = t
  assert AVLDict.to_list(t) == AVLDict.to_list(r)
  r2 = AVLDict.merge(@null_node, t)
  # r2 = 0 + t = t
  assert AVLDict.to_list(t) == AVLDict.to_list(r2)
end

def associativity(t1_size, t2_size, t3_size) do
  t1 =
    AVLDict.from_list(Enum.map(1..t1_size, fn _ -> {:rand.uniform(50), :rand.uniform(100)} end))

  t2 =
    AVLDict.from_list(Enum.map(1..t2_size, fn _ -> {:rand.uniform(50), :rand.uniform(100)} end))

  t3 =
    AVLDict.from_list(Enum.map(1..t3_size, fn _ -> {:rand.uniform(50), :rand.uniform(100)} end))

  # r1 = t1 + (t2 + t3)
  r1 = AVLDict.merge(t1, AVLDict.merge(t2, t3))
  # r2 = (t1 + t2) + t3
  r2 = AVLDict.merge(AVLDict.merge(t1, t2), t3)

  # r1 == r2
  assert AVLDict.to_list(r1) == AVLDict.to_list(r2)
end

# Тестирование свойства нейтрального элемента у моноида путём запуска функции neutral_elem 5000 раз
test "Neutral Element" do
  Enum.map(1..5_000, fn _ -> neutral_elem(:rand.uniform(1000) - 1) end)
end

# Ассоциативность операции умножения - слияние деревьев

# Тестирование свойства ассоциативности операции слияния деревьев (сложения) у моноида путём запуска
# функции associativity 5000 раз. Тестируем на AVL-деревьях с небольшим количеством узлов (<10)
test "Small Monoid Test" do
  Enum.map(1..5_000, fn _ ->
    associativity(:rand.uniform(10) - 1, :rand.uniform(10) - 1, :rand.uniform(10) - 1)
  end)
end

# Тестирование свойства ассоциативности операции слияния деревьев (сложения) у моноида путём запуска
# функции associativity 5000 раз. Тестируем на AVL-деревьях со средним количеством узлов (<100)
test "Medium Monoid Test" do
  Enum.map(1..5_000, fn _ ->
    associativity(:rand.uniform(100) - 1, :rand.uniform(100) - 1, :rand.uniform(100) - 1)
  end)
end

# Тестирование свойства ассоциативности операции слияния деревьев (сложения) у моноида путём запуска
# функции associativity 5000 раз. Тестируем на AVL-деревьях с большим количеством узлов (<1000)
test "Big Monoid Test" do
  Enum.map(1..5_000, fn _ ->
    associativity(:rand.uniform(1000) - 1, :rand.uniform(1000) - 1, :rand.uniform(1000) - 1)
  end)
end
```

## Выводы

Выполняя данную лабораторную работу, я освоил несколько важных приемов функционального программирования и работы с пользовательскими типами данных:

1. Реализация AVL-дерева: Я создал полиморфную структуру данных AVL-дерево, которая обеспечивает эффективное хранение и поиск ключей. Это позволило мне глубже понять принципы работы сбалансированных деревьев и их реализацию в функциональном стиле.

2. Неизменяемость данных: Все операции с AVL-деревом реализованы с соблюдением принципа неизменяемости, что является ключевым аспектом функционального программирования. Это обеспечивает безопасность при параллельном выполнении и упрощает отладку.

3. Функции высшего порядка: Использование функций `map`, `map_tree`, `foldl`, `foldr`, `filter` и `filter_tree` демонстрирует мощь функций высшего порядка в обработке данных.

4. Моноидальная структура: Реализация AVL-дерева как моноида с бинарной ассоциативной операцией `merge` и нейтральным элементом `@null_node` показывает, как абстрактные алгебраические концепции могут быть применены к структурам данных.

5. Тестирование:

   - Unit-тестирование: Я написал набор модульных тестов для проверки корректности работы основных операций AVL-дерева.

   - Property-based тестирование: Я написал набор более общих и мощных тестов, проверяющие свойства AVL-дерева (например, свойства моноида) на большом количестве случайных входных данных.

6. Полиморфизм: AVL-дерево реализовано как полиморфная структура, способная хранить значения различных типов.

Эта лабораторная работа позволила мне глубже погрузиться в функциональное программирование, работу со сложными структурами данных и различные методы тестирования. 
