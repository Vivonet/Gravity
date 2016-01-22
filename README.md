#Gravity
In my thirty-five years of existence in this universe, I have encountered few things as brutally frustrating and disappointing as Apple's Auto Layout engine. For a company that prides itself in the intuitiveness and ease of use of their software, auto layout represents a complete 180° on that stance, instead favouring bizarre and unnatural complexity over simplicity. The result is a beast of a system that takes many long hours to become even remotely proficient in.

Auto layout has its apologists, and while there's no arguing it's a powerful system, the fact remains that if you've ever had to work with auto layout at some point in your career, you're all but guaranteed to have had a frustrating experience.

Auto layout tends to work well in two scenarios:

1. Extremely simple layouts, and
2. Extremely complex layouts.

It fails though, utterly in my opinion, at handling 99% of the layouts typical in modern software: those that need slightly more power than the absolute basic defaults, but which are not so mind-numbingly complex as to require the type of prioritized constraint engine Auto Layout is based upon (especially when 99% of its use is to resize a view from one screen size to a subtly different screen size).

Here's my background: I've always been a Mac guy, but I dabbled with .NET for a while in the early 2000's. During this time I discovered (and eventually fell in love with) WPF, a.k.a. Windows Presentation Foundation. WPF represented a quantum leap forward in the simple expressibility of arbitrary visual layouts using a simple hierarchical structure: XML. (Now, editing XML by hand is a nightmare unto itself, but that's really beside the point.)

After leaving the Windows world and coming back to Apple by means of the iOS platform, I was utterly dismayed at the mediocre layout tools available to me: at first it was Interface Builder with springs and struts. While the springs and struts model was a breeze to understand and worked fairly well for very simple interfaces, it was ultimately very limited in what it could express. But it wasn't until Apple released their "next big thing" in layout that things got truly bad.

"Auto Layout," they called it, as if it were some tongue-in-cheek sarcastic jab. Truly there is nothing automatic about it *at all*. It is in fact painstakingly manual. Now, instead of simply telling the computer which edges of an element should flow and which should be fixed in place, you have to tie individual edges of elements to each other, and chain these bindings together in precisely the right arrangement, all the while having many more things to have to worry about: (constraint priorities, content-hugging, expansion resistance, user-constraints, system-constraints, implicitly generated constraints, placeholder constraints, etc. etc.). Things went from simple but limited to insanely complex overnight.

Anyway if you've made it this far I'm probably preaching to the choir.

I hate Auto Layout. It is an utter failure on Apple's part to pave the way forward for developers and designers who want to spend their time building useful software that looks good and works well. Apple had a chance to really innovate in this area like they so often do in other areas, but instead sent the whole industry a huge leap backwards. This was especially unforgivable to me, who had spent the prior five years experiencing the joys of what interface layout could be (WPF wasn't perfect, don't get me wrong, but what it got right far and away made up for its shortcomings). Here I was going from an engine based on the principles of containment, reusability, object-orientedness, precision and determinism--the things we developers love--to this spaghetti pile of puke known as Auto Layout, where moving one thing in a UI could cause a chain reaction of broken layout constraints that leads to hours of retweaking to get your layout perfect again.

The *good* news is that Auto Layout is now sufficiently powerful enough to act as the foundation for another much-simpler layer built on top of it. Enter: Gravity.

Why "Gravity"?

Well, gravity is simple. It's a law: things attract. Gravity is the universe's way of making things take up the least amount of space, just like your interface elements will automatically size and shrink to their ideal size and will just automatically look good and behave like you want.

Go ahead, sketch out a simple UI on a piece of paper or your favourite app. Looking at it, you already have a good idea of which elements should expand or shrink, and which elements should collapse before other elements. It's usually pretty obvious. Gravity aims to turn that intuitive knowledge into a functioning UI with as little work as possible.

Gravity is inspired on the surface by WPF, but is a much much simpler take on it. You define an interface as a tree: everything has its place in the hierarchy and the resultant interface is generated programmatically with all of the proper layout constraints in place, so you get all the power of auto layout without having to touch it.

Gravity is a layout engine for programmers. Unlike Interface Builder, which presents you with a visualization of your software and requires you to build and tweak that interface graphically (which on the surface sounds great, but start getting into complex views and it becomes a nightmare, especially since Xcode doesn't have any kind of proper interface editing *tools* with standard features like layers and grouping), Gravity lets you tweak your interface *textually*, just like editing a code file. Yeah you have to rebuild and run to see your changes, but the control and precision it gives you is worth it. It's also far, far harder to accidentally do something you have no idea what and end up breaking your entire UI. Interface builder is fragile like that. Gravity is solid foundation.

Gravity is more than a layout engine. Gravity is a metaphor. For the way we picture and convey the information we want to display to our users. It is minimalism and efficiency.

Calling Gravity an "engine" is a bit of a stretch. Auto Layout is still the true engine powering Gravity. Gravity just gives you a much simpler way to specify your interface, and Auto Layout takes care of the real work behind the scenes. It's really just an interpretive layer that converts a simple XML document into a fully-constructed interface. Gravity is the curtain that hides the great and powerful Oz.

Coming soon.