import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
// import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zero/Bloc/Feed/feed_bloc.dart';
import 'package:zero/Cubit/Page_state/page_state_cubit.dart';
import 'package:zero/Global/colors.dart';
import 'package:zero/Model/post.dart';
import 'package:zero/Repository/Auth/auth_repository.dart';
import 'package:zero/Repository/Feed/feed_repository.dart';
import 'package:zero/Screen/Auth/auth_page.dart';
import 'package:zero/Screen/Feed/post_detail_layout.dart';
import 'package:zero/Screen/Feed/side_box.dart';
import 'package:zero/Widgets/Feed/create_post_header.dart';
import 'package:zero/Widgets/Feed/post_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  AuthRepository authRepository = AuthRepository();
  AuthUser? authUser;
  late PageStateCubit _pageStateCubit;
  late FeedBloc _feedBloc;
  List<Post> futurePosts = [];
  @override
  void initState() {
    // Initialize PageStateCubit
    _pageStateCubit = PageStateCubit();
    _feedBloc = FeedBloc(FeedRepository());
    _feedBloc.add(FeedRequested());
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    AuthUser? user = await authRepository.getAuthUser();
    setState(() {
      authUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeedBloc>.value(value: _feedBloc),
        BlocProvider<PageStateCubit>.value(
            value: _pageStateCubit), // Add this line
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
            child: Row(
              children: [
                Row(
                  children: [
                    Text(
                      "Feeds",
                      style: GoogleFonts.roboto(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.white),
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.search_sharp),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return const AuthScreen();
                    }));
                  },
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.background),
                    child: Row(children: [
                      Text('${authUser?.name ?? 'userName'}'),
                      const Gap(8),
                      const CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            NetworkImage("https://thispersondoesnotexist.com/"),
                      ),
                    ]),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: BlocListener<PageStateCubit, PageStateState>(
              listener: (context, state) {
                if (state is PageStatePostView) {
                  // Show post detail layout
                  _buildPostDetailLayout(state.selectedPost);
                }
              },
              child: BlocBuilder<PageStateCubit, PageStateState>(
                builder: (context, state) {
                  if (state is PageStateFeedView) {
                    // Display feed layout
                    return _postChecker();
                  } else if (state is PageStatePostView) {
                    // Display post detail layout
                    return _buildPostDetailLayout(state.selectedPost);
                  } else {
                    return _postChecker();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postChecker() {
    return BlocProvider(
      create: (context) => _feedBloc,
      child: Container(
        color: AppTheme.background,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  if (state is FeedLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is FeedLoaded) {
                    futurePosts = state.posts;
                    return _buildFeedLayout(
                      posts: futurePosts,
                    );
                  } else {
                    return const SizedBox(
                      child: Text("gg"),
                    );
                  }
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedLayout({required List<Post> posts}) {
    if (MediaQuery.of(context).size.width < 600) {
      // Small screen layout
      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostContainer(post: posts[index]);
                },
              ),
            ),
            Container(
              width: double.infinity, // or provide a specific width value
              child: const CreatePostHeader(),
            ),
          ],
        ),
      );
    } else {
      // Large screen layout
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostContainer(post: posts[index]);
                      },
                    ),
                  ),
                  const CreatePostHeader(),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(),
            width: MediaQuery.of(context).size.width * 0.2,
            child: SideBox(),
          )
        ],
      );
    }
  }

  Widget _buildPostDetailLayout(selectedPost) {
    if (selectedPost == null) {
      // Handle the case where there's no selected post
      return const SizedBox(); // or throw an error, depending on your logic
    }
    if (MediaQuery.of(context).size.width < 600) {
      return PostDetailLayout(post: selectedPost);
    } else {
      return Row(children: [
        PostDetailLayout(post: selectedPost),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(),
            //width: MediaQuery.of(context).size.width * 0.2,
          ),
        )
      ]);
    }
  }
}
