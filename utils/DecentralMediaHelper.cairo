%lang starknet

struct Array:
    member len: felt
    member arr: felt*
end


struct User:
    member username: Array
    member image: Array
    member background_image: Array
    member description: Array
    member social_link: Array
    member following: Array
    member followers: Array
    member contents: Array
    member num_ratings: felt
    member sum_ratings: felt
    member created_at: felt
end