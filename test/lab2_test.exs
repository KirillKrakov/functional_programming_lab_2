defmodule Lab2Test do
  alias Lab2.AVLDict
  alias Lab2.Node
  use ExUnit.Case

  @null_node %Node{key: nil, value: nil, left: nil, right: nil, height: 0}

  # Unit-тестирование

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

  def insert_all(l) do
    r =
      :lists.foldl(
        fn {key, value}, acc ->
          cur = AVLDict.insert(acc, key, value)
          assert balance_check(cur) == true
        end,
        @null_node,
        l
      )

    list_r = AVLDict.to_list(r)
    assert ^list_r = :lists.usort(l)
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

  # Property-based тестирование

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
end
