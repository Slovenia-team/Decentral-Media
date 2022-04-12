# Decentral Media
[![Tests and linter](https://github.com/Slovenia-team/Decentral-Media/actions/workflows/python-app.yml/badge.svg)](https://github.com/Slovenia-team/starknet-erc721-storage/actions/workflows/python-app.yml)

Decentralized Media Network on ETH Layer 2.

## The Vision
Our goal is to build a complete decentralized media network controlled by its users. All the content and accounts are on-chain, there will be no central censorship of the contents. We start with paid subscription mode, like Substack and Patreon, then expand into free media following mode like Medium.

## Version 1

### Let your most passionate fans support your creative work via monthly membership NFTs.

You can let your fans become active participants in the work they love by offering them a monthly membership. You give them access to exclusive content, community, and insight into your creative process. In exchange, you get the freedom to do your best work, and the stability you need to build an independent creative career.

### Develop a recurring income stream

Stop rolling the dice of ad revenue and per-stream payouts. Get recurring income through monthly payments from your NFTs.

### Take back creative control

Create what you want and what your audience loves. You don’t have to conform to popular taste or the constraints of ad-based monetization models.

### Build a direct, meaningful connection with your audience

No ads, no trolls, no algorithms. Enjoy direct access and deeper conversations with the people who matter the most.

## Targeted Artists:

- Podcasters
- Musicians
- Visual Artists
- Writers & Journalists
- Gaming Creators
- Educators
- Creators-of-all-kinds

## Implementation

DecentralMedia consists of 4 main contracts all deployed on layer 2: User ERC721, Content ERC721, Comment ERC721 and the main contract (with all the business logic).

## Table of Contents

- [Prerequisites](#prerequisites)
- [User functions](#user-functions)
  *  [get_user_token_id](#get_user_token_id)
  *  [get_user](#get_user)
  *  [create_user](#create_user)
  *  [update_user](#update_user)
  *  [follow](#follow)
  *  [unfollow](#unfollow)
  *  [rate](#rate)
  *  [flag_user](#rate)
  *  [set_user_erc721_contract](#set_user_erc721_contract)
- [Content functions](#content-functions)
  *  [get_content](#get_content)
  *  [create_content](#create_content)
  *  [update_content](#update_content)
  *  [like_content](#like_content)
  *  [dislike_content](#dislike_content)
  *  [set_content_erc721_contract](#set_content_erc721_contract)
- [Comment functions](#comment-functions)
  *  [get_comment](#get_comment)
  *  [create_comment](#create_comment)
  *  [like_comment](#like_comment)
  *  [dislike_comment](#dislike_comment)
  *  [set_comment_erc721_contract](#set_comment_erc721_contract)

## Prerequisites

### Setting up the environment
A detailed guide on how to set up the Starknet environment is accessible at [cairo lang docs](https://www.cairo-lang.org/docs/quickstart.html).

### Set up the project
Clone the repository:
``` 
git clone https://github.com/Slovenia-team/Decentral-Media.git  
```

Pull the OpenZeppelin and starknet-erc721-storage submodules:
``` 
git submodule update --init --recursive
```

Rename ERC721 storage submodule to allow imports.
```
git mv starknet-erc721-storage starknet_erc721_storage
```

## User functions

### `get_user_token_id`

Get token id of user by their address.

#### Parameters:
```
address: felt
```

#### Returns:

```
token_id: Uint256
```

### `get_user`

Get user data.

#### Parameters:
```
address: felt
```

#### Returns:

```
username_len: felt
username: felt*
image_len: felt
image: felt*
background_image_len: felt
background_image: felt*
description_len: felt
description: felt*
social_link_len: felt
social_link: felt*
following_len: felt
following: felt*
followers_len: felt
followers: felt*
contents_len: felt
contents: felt*
rated_len: felt
rated: felt*
rating_len: felt
rating: felt*
created_at: felt
```

### `create_user`

Create a new user on Starknet.

#### Parameters:
```
username_len: felt,
username: felt*
image_len: felt
image: felt*
background_image_len: felt
background_image: felt*
description_len: felt
description: felt*
social_link_len: felt
social_link: felt*
nonce: felt
```

#### Returns:

None.

### `update_user`

Update user data on Starknet.

#### Parameters:
```
token_id: Uint256,
username_len: felt
username: felt*
image_len: felt
image: felt*
background_image_len: felt
background_image: felt*
description_len: felt
description: felt*
social_link_len: felt
social_link: felt*
nonce: felt
```

#### Returns:

None.

### `follow`

Follow the content creator.

#### Parameters:
```
creator_token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `unfollow`

Unfollow the content creator.

#### Parameters:
```
creator_token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `rate`

Rate the content creator. You can only rate a content creator you are following.

#### Parameters:
```
creator_token_id: Uint256
rating: felt
nonce: felt
```

#### Returns:

None.

### `flag_user`

Admin only! Set User erc721 contract address.

#### Parameters:
```
token_id: Uint256
flag: felt
nonce: felt
```

#### Returns:

None.

### `set_user_erc721_contract`

Admin only! Set User erc721 contract address.

#### Parameters:
```
contract: felt
nonce: felt
```

#### Returns:

None.

## Content functions

### `get_content`

Get content data.

#### Parameters:
```
token_id: Uint256
```

#### Returns:

```
content_len: felt,
content: felt*
tags_len: felt
tags: felt*
authors_len: felt
authors: felt*
comments_len: felt
comments: felt*
liked_by_len: felt
liked_by: felt*
disliked_by_len: felt
disliked_by: felt*
likes: felt
views: felt
public: felt
created_at: felt
creator: felt
```

### `create_content`

Create content on Starknet.

#### Parameters:
```
content_len: felt
content: felt*
tags_len: felt
tags: felt*
authors_len: felt
authors: felt*
public: felt
nonce: felt
```

#### Returns:

None.

### `update_content`

Update visibility of content.

#### Parameters:
```
token_id: Uint256
public: felt
nonce: felt
```

#### Returns:

None.

### `like_content`

Like the content.

#### Parameters:
```
token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `dislike_content`

Dislike the content.

#### Parameters:
```
token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `dislike_content`

Dislike the content.

#### Parameters:
```
token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `set_content_erc721_contract`

Admin only! Set Content erc721 contract address.

#### Parameters:
```
contract: felt,
nonce: felt
```

#### Returns:

None.

## Comment functions

### `get_comment`

Get comment data.

#### Parameters:
```
token_id: Uint256
```

#### Returns:

```
comment_len: felt
comment: felt*
liked_by_len: felt
liked_by: felt*
disliked_by_len: felt
disliked_by: felt*
likes: felt
created_at: felt
creator: felt
content: felt
```

### `create_comment`

Create a new comment on a content.

#### Parameters:
```
comment_len: felt
comment: felt*
content_token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `like_comment`

Like a comment.

#### Parameters:
```
token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `dislike_comment`

Dislike a comment.

#### Parameters:
```
token_id: Uint256
nonce: felt
```

#### Returns:

None.

### `set_comment_erc721_contract`

Admin only! Set Comment erc721 contract address.

#### Parameters:
```
contract: felt
nonce: felt
```

#### Returns:

None.
