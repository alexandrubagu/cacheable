defmodule Cacheable.Posts do
  @moduledoc false

  use Cacheable

  alias Cacheable.Post

  @post1 %Post{id: 1, title: "title1", body: "body1"}
  @post2 %Post{id: 2, title: "title2", body: "body2"}

  @cacheable key: "all_posts", ttl: 100
  def all(), do: [@post1, @post2]

  @cacheable ttl: 100
  def get(id), do: Enum.filter(all(), &(&1.id == id))

  def get_by_title(title), do: Enum.find(all(), &(&1.title == title))
end
