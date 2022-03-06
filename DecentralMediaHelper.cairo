%lang starknet

struct Rating:
    member num_ratings : felt
    member sum_ratings : felt
end

struct String:
    member len: felt
    member str: felt*
end

struct Array:
    member len: felt
    member arr: felt*
end

struct Rating:
    member num_ratings: felt
    member sum_ratings: felt
end

struct User:
    member username: String
    member image: String
    member background_image: String
    member description: String
    member social_links_len: felt
    member social_links: String*
    member following: Array
    member followers: Array
    member rating: Rating
    member contents: Array
    member created_at: felt
end