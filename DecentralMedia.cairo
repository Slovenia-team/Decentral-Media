%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from utils.utils import verify_inputs_by_signature
from utils.DecentralMediaHelper import Uint256_to_felt

from UserFunctions import (
    User_getUserTokenId,
    User_getIsFlaged,
    User_getUser,
    User_createUser,
    User_updateUser,
    User_updateContents,
    User_follow,
    User_unfollow,
    User_rate,
    User_setContract,
    User_flag
)

from ContentFunctions import (
    Content_getContent,
    Content_createContent,
    Content_updateContent,
    Content_updateComments,
    Content_like,
    Content_dislike,
    Content_setContract,
)

from CommentFunctions import (
    Comment_getComment,
    Comment_createComment,
    Comment_like,
    Comment_dislike,
    Comment_setContract,
)

#
# Storage
#

@storage_var
func admin() -> (adm : felt):
end


#
# Constructor
#

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    adm : felt):
    admin.write(value=adm)
    return ()
end


#
# Getters
#

@view
func get_user_token_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    token_id : Uint256):
    let (token_id: Uint256) = User_getUserTokenId(address)
    return (token_id)
end

@view
func get_user{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    following_len: felt,
    following: felt*,
    followers_len: felt,
    followers: felt*,
    contents_len: felt,
    contents: felt*,
    rated_len: felt,
    rated: felt*,
    rating_len: felt,
    rating: felt*,
    created_at: felt):

    let (username_len: felt, username: felt*,
    image_len: felt, image: felt*,
    background_image_len: felt, background_image: felt*,
    description_len: felt, description: felt*,
    social_link_len: felt, social_link: felt*,
    following_len: felt, following: felt*,
    followers_len: felt, followers: felt*,
    contents_len: felt, contents: felt*,
    rated_len: felt, rated: felt*,
    rating_len: felt, rating: felt*,
    created_at: felt) = User_getUser(address)

    return (username_len, username, image_len, image, background_image_len, background_image, description_len, description, social_link_len, social_link, following_len, following, followers_len, followers, contents_len, contents, rated_len, rated, rating_len, rating, created_at)
end

@view
func get_content{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id : Uint256) -> (
    content_len: felt,
    content: felt*,
    tags_len: felt,
    tags: felt*,
    authors_len: felt,
    authors: felt*,
    comments_len: felt,
    comments: felt*,
    liked_by_len: felt,
    liked_by: felt*,
    disliked_by_len: felt,
    disliked_by: felt*,
    likes: felt,
    views: felt,
    public: felt,
    created_at: felt,
    creator: felt):

    let (content_len: felt, content: felt*,
    tags_len: felt, tags: felt*,
    authors_len: felt, authors: felt*,
    comments_len: felt, comments: felt*,
    liked_by_len: felt, liked_by: felt*,
    disliked_by_len: felt, disliked_by: felt*,
    likes: felt,
    views: felt,
    public: felt,
    created_at: felt,
    creator: felt) = Content_getContent(token_id)

    return (content_len, content, tags_len, tags, authors_len, authors, comments_len, comments, liked_by_len, liked_by, disliked_by_len, disliked_by, likes, views, public, created_at, creator)
end

@view
func get_comment{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id : Uint256) -> (
    comment_len: felt,
    comment: felt*,
    liked_by_len: felt,
    liked_by: felt*,
    disliked_by_len: felt,
    disliked_by: felt*,
    likes: felt,
    created_at: felt,
    creator: felt,
    content: felt):

    let (comment_len: felt, comment: felt*,
    liked_by_len: felt, liked_by: felt*,
    disliked_by_len: felt, disliked_by: felt*,
    likes: felt,
    created_at: felt,
    creator: felt,
    content: felt) = Comment_getComment(token_id)

    return (comment_len, comment, liked_by_len, liked_by, disliked_by_len, disliked_by, likes, created_at, creator, content)
end

#
# Externals
#

@external
func create_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    nonce: felt):
    User_createUser(username_len, username, image_len, image, background_image_len, background_image, description_len, description, social_link_len, social_link, nonce)
    return ()
end

@external
func update_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    nonce: felt):
    User_updateUser(token_id, username_len, username, image_len, image, background_image_len, background_image, description_len, description, social_link_len, social_link, nonce)
    return ()
end

@external
func follow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    User_follow(creator_token_id, nonce)
    return ()
end

@external
func unfollow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    User_unfollow(creator_token_id, nonce)
    return ()
end

@external
func rate{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    rating: felt,
    nonce: felt):
    User_rate(creator_token_id, rating, nonce)
    return ()
end

@external
func set_user_erc721_contract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    contract : felt,
    nonce : felt):
    let (adm) = admin.read()
    User_setContract(adm, contract, nonce)
    return ()
end

@external
func set_content_erc721_contract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    contract : felt,
    nonce : felt):
    let (adm) = admin.read()
    Content_setContract(adm, contract, nonce)
    return ()
end

@external
func create_content{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    content_len: felt,
    content: felt*,
    tags_len: felt,
    tags: felt*,
    authors_len: felt,
    authors: felt*,
    public: felt,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (creator_token_id: Uint256) = User_getUserTokenId(caller)
    
    let (flaged) = User_getIsFlaged(creator_token_id)
    assert flaged = 0

    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)
    assert_not_zero(creator_token_id_felt)

    let (token_id: Uint256) = Content_createContent(content_len, content, tags_len, tags, authors_len, authors, public, creator_token_id_felt, nonce)
    User_updateContents(creator_token_id, token_id)
    return ()
end

@external
func update_content{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    public: felt,
    nonce: felt):
    Content_updateContent(token_id, public, nonce)
    return ()
end

@external
func like_content{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    nonce: felt):
    let (caller) = get_caller_address()
    let (user_token_id: Uint256) = User_getUserTokenId(caller)
    Content_like(token_id, user_token_id, nonce)
    return ()
end

@external
func dislike_content{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    nonce: felt):
    let (caller) = get_caller_address()
    let (user_token_id: Uint256) = User_getUserTokenId(caller)
    Content_dislike(token_id, user_token_id, nonce)
    return ()
end

@external
func set_comment_erc721_contract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    contract : felt,
    nonce : felt):
    let (adm) = admin.read()
    Comment_setContract(adm, contract, nonce)
    return ()
end

@external
func create_comment{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    comment_len: felt,
    comment: felt*,
    content_token_id: Uint256,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (creator_token_id: Uint256) = User_getUserTokenId(caller)
    
    let (flaged) = User_getIsFlaged(creator_token_id)
    assert flaged = 0

    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)
    assert_not_zero(creator_token_id_felt)

    let (content_token_id_felt: felt) = Uint256_to_felt(content_token_id)

    let (token_id: Uint256) = Comment_createComment(comment_len, comment, creator_token_id_felt, content_token_id_felt, nonce)
    Content_updateComments(content_token_id, token_id)
    return ()
end

@external
func like_comment{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    nonce: felt):
    let (caller) = get_caller_address()
    let (user_token_id: Uint256) = User_getUserTokenId(caller)
    Comment_like(token_id, user_token_id, nonce)
    return ()
end

@external
func dislike_comment{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    nonce: felt):
    let (caller) = get_caller_address()
    let (user_token_id: Uint256) = User_getUserTokenId(caller)
    Comment_dislike(token_id, user_token_id, nonce)
    return ()
end

@external
func flag_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    flag: felt,
    nonce: felt):
    let (adm) = admin.read()
    User_flag(adm, token_id, flag, nonce)
    return ()
end